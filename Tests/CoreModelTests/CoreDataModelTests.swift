//
//  CoreDataModelTests.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/17/25.
//

#if canImport(CoreData)

import Foundation
import CoreData
import Testing
@testable import CoreModel
@testable import CoreDataModel

// - Note: `@Test`/`@Suite` can't be combined with a declaration-level `@available` — the
//   macro expansion requires the declaration to be unconditionally available. The APIs this
//   suite exercises (`ManagedObjectViewContext`, `NSPersistentContainer.syncLoadPersistentStores()`,
//   etc.) need macOS 12/iOS 15/watchOS 8/tvOS 15, below this package's deployment target, so
//   each test guards its body with a runtime `if #available` instead.
@Suite struct CoreDataModelTests {

    static func makeContext() throws -> NSManagedObjectContext {
        let model = Model(entities: Person.self, Event.self)
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel(model: model))
        try coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        return context
    }

    /// Mirrors the `Person` entity for `#Predicate` conversion.
    struct PersonRecord {

        var name: String
        var age: Int
        var events: [EventRecord]
    }

    /// Mirrors the `Event` entity for `#Predicate` conversion.
    struct EventRecord {

        var name: String
    }

    @Test func attributeTypeConversion() throws {
        guard #available(macOS 12, iOS 15, watchOS 8, tvOS 15, *) else {
            return
        }
        // CoreModel -> CoreData
        #expect(NSAttributeType(attributeType: .bool) == .booleanAttributeType)
        #expect(NSAttributeType(attributeType: .int16) == .integer16AttributeType)
        #expect(NSAttributeType(attributeType: .int32) == .integer32AttributeType)
        #expect(NSAttributeType(attributeType: .int64) == .integer64AttributeType)
        #expect(NSAttributeType(attributeType: .float) == .floatAttributeType)
        #expect(NSAttributeType(attributeType: .double) == .doubleAttributeType)
        #expect(NSAttributeType(attributeType: .string) == .stringAttributeType)
        #expect(NSAttributeType(attributeType: .data) == .binaryDataAttributeType)
        #expect(NSAttributeType(attributeType: .date) == .dateAttributeType)
        #expect(NSAttributeType(attributeType: .uuid) == .UUIDAttributeType)
        #expect(NSAttributeType(attributeType: .url) == .URIAttributeType)
        #expect(NSAttributeType(attributeType: .decimal) == .decimalAttributeType)
        // CoreData -> CoreModel round trip
        for type in [AttributeType.bool, .int16, .int32, .int64, .float, .double, .string, .data, .date, .uuid, .url, .decimal] {
            #expect(AttributeType(attributeType: NSAttributeType(attributeType: type)) == type)
        }
        // unsupported CoreData types
        #expect(AttributeType(attributeType: .undefinedAttributeType) == nil)
        #expect(AttributeType(attributeType: .transformableAttributeType) == nil)
        #expect(AttributeType(attributeType: .objectIDAttributeType) == nil)
        #if swift(>=5.9)
        #expect(AttributeType(attributeType: .compositeAttributeType) == nil)
        #endif
    }

    @Test func comparisonModifierConversion() throws {
        guard #available(macOS 12, iOS 15, watchOS 8, tvOS 15, *) else {
            return
        }
        #expect(FetchRequest.Predicate.Comparison.Modifier.all.toFoundation() == .all)
        #expect(FetchRequest.Predicate.Comparison.Modifier.any.toFoundation() == .any)
    }

    @Test func functionSortDescriptorNotConvertible() throws {
        guard #available(macOS 12, iOS 15, watchOS 8, tvOS 15, *) else {
            return
        }
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
        #expect(sortDescriptors.count == 2)
        #expect(sortDescriptors.first?.key == "name")
    }

    @Test func contextModelStorageInsert() throws {
        guard #available(macOS 12, iOS 15, watchOS 8, tvOS 15, *) else {
            return
        }
        let context = try Self.makeContext()
        let person = Person(name: "Alice", age: 30)
        // single insert through the ModelStorage conformance
        try context.insert(person.encode())
        #expect(try context.count(FetchRequest(entity: Person.entityName)) == 1)
        // batch insert through the ModelStorage conformance
        let more = [Person(name: "Bob", age: 25), Person(name: "Charlie", age: 35)]
        try context.insert(more.map { try! $0.encode() })
        #expect(try context.count(FetchRequest(entity: Person.entityName)) == 3)
        // single delete
        try context.delete(Person.entityName, for: ObjectID(person.id))
        #expect(try context.count(FetchRequest(entity: Person.entityName)) == 2)
        // deleting a missing object is a no-op
        try context.delete(Person.entityName, for: ObjectID(UUID()))
        #expect(try context.count(FetchRequest(entity: Person.entityName)) == 2)
    }

    @Test func contextInMemoryFetchID() throws {
        guard #available(macOS 12, iOS 15, watchOS 8, tvOS 15, *) else {
            return
        }
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
        #expect(try context.fetchID(request) == [ObjectID(person.id)])
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
        #expect(results.count == 1)
        #expect(results[0].attributes["name"] == .string("alina"))
    }

    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    @Test func arithmeticPredicateFetch() throws {

        let context = try Self.makeContext()
        try context.insert([
            Person(name: "Alice", age: 30).encode(),
            Person(name: "Bob", age: 17).encode()
        ])

        // CoreModel API: age * 2 >= 40, bridged to NSExpression's multiply:by:
        let direct = FetchRequest.Predicate.Expression
            .arithmetic(.init(function: .multiply, left: .keyPath("age"), right: .attribute(.int64(2))))
            .compare(.greaterThanOrEqualTo, .attribute(.int64(40)))
        let directResults = try context.fetch(FetchRequest(entity: Person.entityName, predicate: direct))
        #expect(directResults.map { $0.attributes["name"] } == [.string("Alice")])

        // Foundation.Predicate: age + 1 >= 21
        let converted = try FetchRequest.Predicate(#Predicate<PersonRecord> { $0.age + 1 >= 21 })
        let convertedResults = try context.fetch(FetchRequest(entity: Person.entityName, predicate: converted))
        #expect(convertedResults.map { $0.attributes["name"] } == [.string("Alice")])
    }

    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    @Test func modifierPredicateFetch() throws {

        let context = try Self.makeContext()
        let wwdc = Event(name: "WWDC", date: Date())
        let other = Event(name: "Other", date: Date())
        try context.insert([wwdc.encode(), other.encode()])
        try context.insert([
            Person(name: "Alice", age: 30, events: [wwdc.id, other.id]).encode(),
            Person(name: "Bob", age: 17, events: [other.id]).encode(),
            Person(name: "Carol", age: 25, events: []).encode()
        ])

        // CoreModel API: ANY events.name == "WWDC"
        let anyDirect = "events.name".compare(.any, .equalTo, [], .attribute(.string("WWDC")))
        let anyResults = try context.fetch(FetchRequest(entity: Person.entityName, predicate: anyDirect))
        #expect(anyResults.map { $0.attributes["name"] } == [.string("Alice")])

        // Foundation.Predicate: contains(where:) converts to the same ANY comparison
        let anyConverted = try FetchRequest.Predicate(#Predicate<PersonRecord> { $0.events.contains { $0.name == "WWDC" } })
        #expect(anyConverted == anyDirect)

        // CoreModel API: ALL events.name == "Other".
        // Carol has no events, so the comparison holds vacuously — the same semantics
        // CoreModel's in-memory evaluator implements, verified here against CoreData itself.
        let allDirect = "events.name".compare(.all, .equalTo, [], .attribute(.string("Other")))
        let allRequest = FetchRequest(entity: Person.entityName, sortDescriptors: [.init(property: "name")], predicate: allDirect)
        let allResults = try context.fetch(allRequest)
        #expect(allResults.map { $0.attributes["name"] } == [.string("Bob"), .string("Carol")])

        // Foundation.Predicate: allSatisfy converts to the same ALL comparison
        let allConverted = try FetchRequest.Predicate(#Predicate<PersonRecord> { $0.events.allSatisfy { $0.name == "Other" } })
        #expect(allConverted == allDirect)
        let allConvertedResults = try context.fetch(
            FetchRequest(entity: Person.entityName, sortDescriptors: [.init(property: "name")], predicate: allConverted)
        )
        #expect(allConvertedResults.map { $0.attributes["name"] } == [.string("Bob"), .string("Carol")])

        // the in-memory evaluator agrees with CoreData on the same objects
        let objects = try context.fetch(FetchRequest(entity: Person.entityName))
            + context.fetch(FetchRequest(entity: Event.entityName))
        let inMemory = allRequest.evaluate(objects)
        #expect(inMemory.map { $0.attributes["name"] } == [.string("Bob"), .string("Carol")])
    }

    @available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, *)
    @Test func regexPredicateFetch() throws {

        let context = try Self.makeContext()
        try context.insert([
            Person(name: "Alice", age: 30).encode(),
            Person(name: "Bob", age: 17).encode()
        ])

        // Foundation.Predicate: the captured pattern becomes a MATCHES comparison
        let regex = try Regex("Al[a-z]+")
        let converted = try FetchRequest.Predicate(#Predicate<PersonRecord> { $0.name.contains(regex) })
        #expect(converted == "name".compare(.matches, .attribute(.string(".*Al[a-z]+.*"))))
        let results = try context.fetch(FetchRequest(entity: Person.entityName, predicate: converted))
        #expect(results.map { $0.attributes["name"] } == [.string("Alice")])

        // the in-memory evaluator agrees with CoreData on the same objects
        let objects = try context.fetch(FetchRequest(entity: Person.entityName))
        #expect(objects.filtered(by: converted).map { $0.attributes["name"] } == [.string("Alice")])
    }

    @Test func nullRelationshipInsert() throws {
        guard #available(macOS 12, iOS 15, watchOS 8, tvOS 15, *) else {
            return
        }
        let context = try Self.makeContext()
        var data = Person(name: "Loner", age: 40).encode()
        data.relationships[PropertyKey(Person.CodingKeys.events)] = .null
        // batch insert path (exercises relationship prefetch with a null value)
        try context.insert([data])
        let fetched = try context.fetch(Person.entityName, for: data.id)
        // CoreData represents an empty to-many relationship as an empty set
        #expect(fetched?.relationships[PropertyKey(Person.CodingKeys.events)] == .toMany([]))
    }

    @MainActor
    @Test func managedObjectViewContextObservation() async throws {
        guard #available(macOS 12, iOS 15, watchOS 8, tvOS 15, *) else {
            return
        }
        let context = try Self.makeContext()
        let viewContext = ManagedObjectViewContext(context: context)
        var changes = 0
        let cancellable = viewContext.objectWillChange.sink { changes += 1 }
        defer { cancellable.cancel() }
        // mutate the observed context to trigger change and save notifications
        try context.insert(Person(name: "Alice", age: 30).encode())
        // - Note: `RunLoop.main.run(until:)` pumped the real main run loop under XCTest's
        //   synchronous main-thread execution; Swift Testing's concurrency model doesn't
        //   guarantee the same thing, so poll briefly instead of blocking on it.
        for _ in 0..<20 where changes == 0 {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(changes > 0)
        // ViewContext conformance
        #expect(try viewContext.count(FetchRequest(entity: Person.entityName)) == 1)
        #expect(try viewContext.fetchID(FetchRequest(entity: Person.entityName)).count == 1)
        #expect(try viewContext.fetch(FetchRequest(entity: Person.entityName)).count == 1)
    }

    @Test func persistentContainerFetchAndDelete() async throws {
        guard #available(macOS 12, iOS 15, watchOS 8, tvOS 15, *) else {
            return
        }
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
        #expect(results.count == 1)
        // delete a single object
        try await container.delete(Person.entityName, for: ObjectID(person.id))
        let remaining = try await container.count(FetchRequest(entity: Person.entityName))
        #expect(remaining == 0)
    }

    @Test func storageLoadFailure() async throws {
        guard #available(macOS 12, iOS 15, watchOS 8, tvOS 15, *) else {
            return
        }
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
            Issue.record("Expected store load to fail")
        } catch {
            // expected
        }
        // healthy storage still works after exercising the failure path
        _ = try await storage.count(FetchRequest(entity: Person.entityName))
    }

    @MainActor
    @Test func viewContextLoadFailure() throws {
        guard #available(macOS 12, iOS 15, watchOS 8, tvOS 15, *) else {
            return
        }
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
        #expect(results ?? [] == [])
    }
}

#endif
