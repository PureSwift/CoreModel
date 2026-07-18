//
//  CoreDataModelTests.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/17/25.
//

#if canImport(CoreData)

import Foundation
import CoreData
import XCTest
@testable import CoreModel
@testable import CoreDataModel

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
final class CoreDataModelTests: XCTestCase {

    static func makeContext() throws -> NSManagedObjectContext {
        let model = Model(entities: Person.self, Event.self)
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel(model: model))
        try coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        return context
    }

    func testAttributeTypeConversion() {
        // CoreModel -> CoreData
        XCTAssertEqual(NSAttributeType(attributeType: .bool), .booleanAttributeType)
        XCTAssertEqual(NSAttributeType(attributeType: .int16), .integer16AttributeType)
        XCTAssertEqual(NSAttributeType(attributeType: .int32), .integer32AttributeType)
        XCTAssertEqual(NSAttributeType(attributeType: .int64), .integer64AttributeType)
        XCTAssertEqual(NSAttributeType(attributeType: .float), .floatAttributeType)
        XCTAssertEqual(NSAttributeType(attributeType: .double), .doubleAttributeType)
        XCTAssertEqual(NSAttributeType(attributeType: .string), .stringAttributeType)
        XCTAssertEqual(NSAttributeType(attributeType: .data), .binaryDataAttributeType)
        XCTAssertEqual(NSAttributeType(attributeType: .date), .dateAttributeType)
        XCTAssertEqual(NSAttributeType(attributeType: .uuid), .UUIDAttributeType)
        XCTAssertEqual(NSAttributeType(attributeType: .url), .URIAttributeType)
        XCTAssertEqual(NSAttributeType(attributeType: .decimal), .decimalAttributeType)
        // CoreData -> CoreModel round trip
        for type in [AttributeType.bool, .int16, .int32, .int64, .float, .double, .string, .data, .date, .uuid, .url, .decimal] {
            XCTAssertEqual(AttributeType(attributeType: NSAttributeType(attributeType: type)), type)
        }
        // unsupported CoreData types
        XCTAssertNil(AttributeType(attributeType: .undefinedAttributeType))
        XCTAssertNil(AttributeType(attributeType: .transformableAttributeType))
        XCTAssertNil(AttributeType(attributeType: .objectIDAttributeType))
        #if swift(>=5.9)
        XCTAssertNil(AttributeType(attributeType: .compositeAttributeType))
        #endif
    }

    func testComparisonModifierConversion() {
        XCTAssertEqual(FetchRequest.Predicate.Comparison.Modifier.all.toFoundation(), .all)
        XCTAssertEqual(FetchRequest.Predicate.Comparison.Modifier.any.toFoundation(), .any)
    }

    func testFunctionSortDescriptorNotConvertible() {
        // function-based sort terms can't be represented in NSFetchRequest and are dropped
        let request = FetchRequest(
            entity: "Person",
            sortDescriptors: [
                .init(term: .function(.init(name: "f", arguments: [.keyPath("name")])), ascending: true),
                .init(property: "name", ascending: true)
            ]
        )
        let sortDescriptors = request.toFoundation().sortDescriptors ?? []
        // only the property sort plus the built-in id tiebreaker survive
        XCTAssertEqual(sortDescriptors.count, 2)
        XCTAssertEqual(sortDescriptors.first?.key, "name")
    }

    func testContextModelStorageInsert() throws {
        let context = try Self.makeContext()
        let person = Person(name: "Alice", age: 30)
        // single insert through the ModelStorage conformance
        try context.insert(person.encode())
        XCTAssertEqual(try context.count(FetchRequest(entity: Person.entityName)), 1)
        // batch insert through the ModelStorage conformance
        let more = [Person(name: "Bob", age: 25), Person(name: "Charlie", age: 35)]
        try context.insert(more.map { try! $0.encode() })
        XCTAssertEqual(try context.count(FetchRequest(entity: Person.entityName)), 3)
        // single delete
        try context.delete(Person.entityName, for: ObjectID(person.id))
        XCTAssertEqual(try context.count(FetchRequest(entity: Person.entityName)), 2)
        // deleting a missing object is a no-op
        try context.delete(Person.entityName, for: ObjectID(UUID()))
        XCTAssertEqual(try context.count(FetchRequest(entity: Person.entityName)), 2)
    }

    func testContextInMemoryFetchID() throws {
        let context = try Self.makeContext()
        try context.register(function: DatabaseFunction(name: "lower", argumentCount: 1) { arguments in
            guard case let .string(value) = arguments[0] else { return nil }
            return .string(value.lowercased())
        })
        let person = Person(name: "Alice", age: 30)
        try context.insert(person.encode())
        let lower = FetchRequest.Predicate.Expression.function(.init(name: "lower", arguments: [.keyPath("name")]))
        let request = FetchRequest(
            entity: Person.entityName,
            predicate: lower.compare(.equalTo, .attribute(.string("alice")))
        )
        XCTAssertEqual(try context.fetchID(request), [ObjectID(person.id)])
        // in-memory path with limit and offset
        try context.insert(Person(name: "alina", age: 20).encode())
        let paged = FetchRequest(
            entity: Person.entityName,
            sortDescriptors: [.init(term: .function(.init(name: "lower", arguments: [.keyPath("name")])), ascending: true)],
            predicate: lower.compare(.beginsWith, .attribute(.string("al"))),
            fetchLimit: 1,
            fetchOffset: 1
        )
        let results = try context.fetch(paged)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].attributes["name"], .string("alina"))
    }

    func testNullRelationshipInsert() throws {
        let context = try Self.makeContext()
        var data = Person(name: "Loner", age: 40).encode()
        data.relationships[PropertyKey(Person.CodingKeys.events)] = .null
        // batch insert path (exercises relationship prefetch with a null value)
        try context.insert([data])
        let fetched = try context.fetch(Person.entityName, for: data.id)
        // CoreData represents an empty to-many relationship as an empty set
        XCTAssertEqual(fetched?.relationships[PropertyKey(Person.CodingKeys.events)], .toMany([]))
    }

    @MainActor
    func testManagedObjectViewContextObservation() throws {
        let context = try Self.makeContext()
        let viewContext = ManagedObjectViewContext(context: context)
        var changes = 0
        let cancellable = viewContext.objectWillChange.sink { changes += 1 }
        defer { cancellable.cancel() }
        // mutate the observed context to trigger change and save notifications
        try context.insert(Person(name: "Alice", age: 30).encode())
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        XCTAssertGreaterThan(changes, 0)
        // ViewContext conformance
        XCTAssertEqual(try viewContext.count(FetchRequest(entity: Person.entityName)), 1)
        XCTAssertEqual(try viewContext.fetchID(FetchRequest(entity: Person.entityName)).count, 1)
        XCTAssertEqual(try viewContext.fetch(FetchRequest(entity: Person.entityName)).count, 1)
    }

    func testPersistentContainerFetchAndDelete() async throws {
        let model = Model(entities: Person.self, Event.self)
        let container = NSPersistentContainer(
            name: "Test\(UUID())",
            managedObjectModel: NSManagedObjectModel(model: model)
        )
        try container.syncLoadPersistentStores()
        let person = Person(name: "Alice", age: 30)
        try await container.insert(person.encode())
        // fetch with a fetch request
        let results = try await container.fetch(FetchRequest(entity: Person.entityName))
        XCTAssertEqual(results.count, 1)
        // delete a single object
        try await container.delete(Person.entityName, for: ObjectID(person.id))
        let remaining = try await container.count(FetchRequest(entity: Person.entityName))
        XCTAssertEqual(remaining, 0)
    }

    func testStorageLoadFailure() async throws {
        // a store URL inside a nonexistent directory fails to load
        let description = NSPersistentStoreDescription(
            url: URL(fileURLWithPath: "/nonexistent-\(UUID())/store.sqlite")
        )
        description.type = NSSQLiteStoreType
        let storage = PersistentStorageTests.makeStorage(model: Model(entities: Person.self, Event.self))
        let failing = PersistentContainerStorage(
            name: "Failing\(UUID())",
            model: Model(entities: Person.self, Event.self),
            storeDescriptions: [description]
        )
        do {
            _ = try await failing.fetch(FetchRequest(entity: Person.entityName))
            XCTFail("Expected store load to fail")
        } catch {
            // expected
        }
        // healthy storage still works after exercising the failure path
        _ = try await storage.count(FetchRequest(entity: Person.entityName))
    }

    @MainActor
    func testViewContextLoadFailure() throws {
        let description = NSPersistentStoreDescription(
            url: URL(fileURLWithPath: "/nonexistent-\(UUID())/store.sqlite")
        )
        description.type = NSSQLiteStoreType
        let failing = PersistentContainerStorage(
            name: "Failing\(UUID())",
            model: Model(entities: Person.self, Event.self),
            storeDescriptions: [description]
        )
        // the sync load swallows the error; the view context is still created and
        // fetches simply return no results against the unloaded store
        let viewContext = try failing.viewContext
        let results = try? viewContext.fetch(FetchRequest(entity: Person.entityName))
        XCTAssertEqual(results ?? [], [])
    }
}

#endif
