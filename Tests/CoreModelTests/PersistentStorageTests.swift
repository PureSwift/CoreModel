//
//  PersistentStorageTests.swift
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

/// Entity exercising every supported attribute type.
@Entity
struct AllTypes: Equatable, Hashable, Codable, Identifiable {

    let id: UUID

    @Attribute
    var boolValue: Bool

    @Attribute
    var int16Value: Int16

    @Attribute
    var int32Value: Int32

    @Attribute
    var int64Value: Int64

    @Attribute
    var floatValue: Float

    @Attribute
    var doubleValue: Double

    @Attribute
    var stringValue: String

    @Attribute
    var dateValue: Date

    @Attribute
    var dataValue: Data

    @Attribute
    var uuidValue: UUID

    @Attribute
    var urlValue: URL

    @Attribute
    var decimalValue: Decimal

    @Attribute
    var optionalString: String?

    init(
        id: UUID,
        boolValue: Bool,
        int16Value: Int16,
        int32Value: Int32,
        int64Value: Int64,
        floatValue: Float,
        doubleValue: Double,
        stringValue: String,
        dateValue: Date,
        dataValue: Data,
        uuidValue: UUID,
        urlValue: URL,
        decimalValue: Decimal,
        optionalString: String?
    ) {
        self.id = id
        self.boolValue = boolValue
        self.int16Value = int16Value
        self.int32Value = int32Value
        self.int64Value = int64Value
        self.floatValue = floatValue
        self.doubleValue = doubleValue
        self.stringValue = stringValue
        self.dateValue = dateValue
        self.dataValue = dataValue
        self.uuidValue = uuidValue
        self.urlValue = urlValue
        self.decimalValue = decimalValue
        self.optionalString = optionalString
    }

    enum CodingKeys: CodingKey {
        case id
        case boolValue
        case int16Value
        case int32Value
        case int64Value
        case floatValue
        case doubleValue
        case stringValue
        case dateValue
        case dataValue
        case uuidValue
        case urlValue
        case decimalValue
        case optionalString
    }
}

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
final class PersistentStorageTests: XCTestCase {

    static func makeStorage(model: Model = Model(entities: Person.self, Event.self, AllTypes.self)) -> PersistentContainerStorage {
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        return PersistentContainerStorage(
            name: "Test\(UUID())",
            model: model,
            storeDescriptions: [description]
        )
    }

    static func makeAllTypes() -> AllTypes {
        AllTypes(
            id: UUID(),
            boolValue: true,
            int16Value: 16,
            int32Value: 32,
            int64Value: 64,
            floatValue: 1.5,
            doubleValue: 2.5,
            stringValue: "test",
            dateValue: Date(timeIntervalSince1970: 100),
            dataValue: Data([0x01, 0x02]),
            uuidValue: UUID(),
            urlValue: URL(string: "https://example.com")!,
            decimalValue: Decimal(string: "3.14")!,
            optionalString: nil
        )
    }

    func testAllAttributeTypesRoundTrip() async throws {
        let storage = Self.makeStorage()
        var value = Self.makeAllTypes()
        try await storage.insert(value)
        var fetched = try await storage.fetch(AllTypes.self, for: value.id)
        XCTAssertEqual(fetched, value)
        // update with non-nil optional
        value.optionalString = "present"
        value.stringValue = "updated"
        try await storage.insert(value)
        fetched = try await storage.fetch(AllTypes.self, for: value.id)
        XCTAssertEqual(fetched, value)
        XCTAssertEqual(fetched?.optionalString, "present")
    }

    func testStorageCRUD() async throws {
        let storage = Self.makeStorage()
        let people = [
            Person(name: "Alice", age: 30),
            Person(name: "Bob", age: 25),
            Person(name: "Charlie", age: 35)
        ]
        // batch insert (ModelData array)
        try await storage.insert(people.map { try! $0.encode() })
        // count
        let fetchRequest = FetchRequest(entity: Person.entityName)
        let total = try await storage.count(fetchRequest)
        XCTAssertEqual(total, 3)
        // typed count
        let typedCount = try await storage.count(Person.self)
        XCTAssertEqual(typedCount, 3)
        // fetchID
        let ids = try await storage.fetchID(fetchRequest)
        XCTAssertEqual(Set(ids), Set(people.map { ObjectID($0.id) }))
        // typed fetch with sort and predicate
        let sorted: [Person] = try await storage.fetch(
            Person.self,
            sortDescriptors: [.init(property: PropertyKey(Person.CodingKeys.name), ascending: false)],
            predicate: Person.CodingKeys.age.compare(.greaterThan, .attribute(.int16(26)))
        )
        XCTAssertEqual(sorted.map { $0.name }, ["Charlie", "Alice"])
        // fetch with limit and offset
        let limited = try await storage.fetch(
            FetchRequest(
                entity: Person.entityName,
                sortDescriptors: [.init(property: PropertyKey(Person.CodingKeys.name), ascending: true)],
                fetchLimit: 1,
                fetchOffset: 1
            )
        )
        XCTAssertEqual(limited.count, 1)
        XCTAssertEqual(limited[0].attributes[PropertyKey(Person.CodingKeys.name)], .string("Bob"))
        // fetch missing object
        let missing = try await storage.fetch(Person.self, for: UUID())
        XCTAssertNil(missing)
        // typed delete
        try await storage.delete(Person.self, for: people[0].id)
        // batch delete by id
        try await storage.delete(Person.entityName, for: [ObjectID(people[1].id), ObjectID(people[2].id)])
        let remaining = try await storage.count(fetchRequest)
        XCTAssertEqual(remaining, 0)
    }

    func testStorageCustomFunction() async throws {
        let storage = Self.makeStorage()
        try await storage.register(function: DatabaseFunction(name: "upperName", argumentCount: 1) { arguments in
            guard case let .string(name) = arguments[0] else { return nil }
            return .string(name.uppercased())
        })
        try await storage.insert(Person(name: "alice", age: 30))
        let upperName = FetchRequest.Predicate.Expression.function(
            .init(name: "upperName", arguments: [.keyPath(PredicateKeyPath(rawValue: "name"))])
        )
        let request = FetchRequest(
            entity: Person.entityName,
            predicate: .comparison(.init(left: upperName, right: .attribute(.string("ALICE")), type: .equalTo))
        )
        let matches = try await storage.fetch(request)
        XCTAssertEqual(matches.count, 1)
    }

    @MainActor
    func testViewContext() async throws {
        let storage = Self.makeStorage()
        let person = Person(name: "Alice", age: 30)
        try await storage.insert(person)
        let viewContext = try storage.viewContext
        // repeated access reuses the lazily created context
        _ = try storage.viewContext
        // typed fetch by id
        let fetched = try viewContext.fetch(Person.self, for: person.id)
        XCTAssertEqual(fetched, person)
        // typed fetch with predicate
        let all: [Person] = try viewContext.fetch(
            Person.self,
            sortDescriptors: [.init(property: PropertyKey(Person.CodingKeys.name), ascending: true)],
            predicate: Person.CodingKeys.name.compare(.equalTo, .attribute(.string("Alice")))
        )
        XCTAssertEqual(all, [person])
        // typed count
        XCTAssertEqual(try viewContext.count(Person.self), 1)
        // count with fetch request
        XCTAssertEqual(try viewContext.count(FetchRequest(entity: Person.entityName)), 1)
        // fetch missing
        XCTAssertNil(try viewContext.fetch(Person.self, for: UUID()))
    }

    func testNSPersistentContainerStorage() async throws {
        let model = Model(entities: Person.self, Event.self, AllTypes.self)
        let container = NSPersistentContainer(
            name: "Test\(UUID())",
            managedObjectModel: NSManagedObjectModel(model: model)
        )
        container.persistentStoreDescriptions.forEach { $0.shouldAddStoreAsynchronously = false }
        try container.syncLoadPersistentStores()
        let people = [
            Person(name: "Alice", age: 30),
            Person(name: "Bob", age: 25)
        ]
        try await container.insert(people.map { try! $0.encode() })
        let fetchRequest = FetchRequest(entity: Person.entityName)
        let count = try await container.count(fetchRequest)
        XCTAssertEqual(count, 2)
        let ids = try await container.fetchID(fetchRequest)
        XCTAssertEqual(Set(ids), Set(people.map { ObjectID($0.id) }))
        try await container.register(function: DatabaseFunction(name: "identity", argumentCount: 1) { arguments in arguments[0] })
        try await container.delete(Person.entityName, for: ids)
        let remaining = try await container.count(fetchRequest)
        XCTAssertEqual(remaining, 0)
    }
}

#endif
