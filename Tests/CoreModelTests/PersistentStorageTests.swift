//
//  PersistentStorageTests.swift
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

// - Note: `@Test`/`@Suite` can't be combined with a declaration-level `@available` — see
//   CoreDataModelTests.swift for the same note. Each test guards its body with a runtime
//   `if #available` instead.
@Suite(.serialized) struct PersistentStorageTests {

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

    @Test func allAttributeTypesRoundTrip() async throws {
        guard #available(macOS 12, iOS 15, watchOS 8, tvOS 15, *) else {
            return
        }
        let storage = Self.makeStorage()
        var value = Self.makeAllTypes()
        try await storage.insert(value)
        var fetched = try await storage.fetch(AllTypes.self, for: value.id)
        #expect(fetched == value)
        // update with non-nil optional
        value.optionalString = "present"
        value.stringValue = "updated"
        try await storage.insert(value)
        fetched = try await storage.fetch(AllTypes.self, for: value.id)
        #expect(fetched == value)
        #expect(fetched?.optionalString == "present")
    }

    @Test func storageCRUD() async throws {
        guard #available(macOS 12, iOS 15, watchOS 8, tvOS 15, *) else {
            return
        }
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
        #expect(total == 3)
        // typed count
        let typedCount = try await storage.count(Person.self)
        #expect(typedCount == 3)
        // fetchID
        let ids = try await storage.fetchID(fetchRequest)
        #expect(Set(ids) == Set(people.map { ObjectID($0.id) }))
        // typed fetch with sort and predicate
        let sorted: [Person] = try await storage.fetch(
            Person.self,
            sortDescriptors: [.init(property: PropertyKey(Person.CodingKeys.name), ascending: false)],
            predicate: Person.CodingKeys.age.compare(.greaterThan, .attribute(.int16(26)))
        )
        #expect(sorted.map { $0.name } == ["Charlie", "Alice"])
        // fetch with limit and offset
        let limited = try await storage.fetch(
            FetchRequest(
                entity: Person.entityName,
                sortDescriptors: [.init(property: PropertyKey(Person.CodingKeys.name), ascending: true)],
                fetchLimit: 1,
                fetchOffset: 1
            )
        )
        #expect(limited.count == 1)
        #expect(limited[0].attributes[PropertyKey(Person.CodingKeys.name)] == .string("Bob"))
        // fetch missing object
        let missing = try await storage.fetch(Person.self, for: UUID())
        #expect(missing == nil)
        // typed delete
        try await storage.delete(Person.self, for: people[0].id)
        // batch delete by id
        try await storage.delete(Person.entityName, for: [ObjectID(people[1].id), ObjectID(people[2].id)])
        let remaining = try await storage.count(fetchRequest)
        #expect(remaining == 0)
    }

    @Test func storageCustomFunction() async throws {
        guard #available(macOS 12, iOS 15, watchOS 8, tvOS 15, *) else {
            return
        }
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
        #expect(matches.count == 1)
    }

    @MainActor
    @Test func viewContext() async throws {
        guard #available(macOS 12, iOS 15, watchOS 8, tvOS 15, *) else {
            return
        }
        let storage = Self.makeStorage()
        let person = Person(name: "Alice", age: 30)
        try await storage.insert(person)
        let viewContext = try storage.viewContext
        // repeated access reuses the lazily created context
        _ = try storage.viewContext
        // typed fetch by id
        let fetched = try viewContext.fetch(Person.self, for: person.id)
        #expect(fetched == person)
        // typed fetch with predicate
        let all: [Person] = try viewContext.fetch(
            Person.self,
            sortDescriptors: [.init(property: PropertyKey(Person.CodingKeys.name), ascending: true)],
            predicate: Person.CodingKeys.name.compare(.equalTo, .attribute(.string("Alice")))
        )
        #expect(all == [person])
        // typed count
        #expect(try viewContext.count(Person.self) == 1)
        // count with fetch request
        #expect(try viewContext.count(FetchRequest(entity: Person.entityName)) == 1)
        // fetch missing
        #expect(try viewContext.fetch(Person.self, for: UUID()) == nil)
    }

    @Test func nsPersistentContainerStorage() async throws {
        guard #available(macOS 12, iOS 15, watchOS 8, tvOS 15, *) else {
            return
        }
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
        #expect(count == 2)
        let ids = try await container.fetchID(fetchRequest)
        #expect(Set(ids) == Set(people.map { ObjectID($0.id) }))
        try await container.register(function: DatabaseFunction(name: "identity", argumentCount: 1) { arguments in arguments[0] })
        try await container.delete(Person.entityName, for: ids)
        let remaining = try await container.count(fetchRequest)
        #expect(remaining == 0)
    }
}

#endif
