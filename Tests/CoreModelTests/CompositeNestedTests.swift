//
//  CompositeNestedTests.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 8/16/26.
//

import Foundation
import Testing
@testable import CoreModel
#if canImport(CoreData)
import CoreData
@testable import CoreDataModel
#endif

/// Nested composite attributes — a composite whose element is itself a composite —
/// exercised identically against the in-memory store and CoreData.
///
/// Every assertion lives in a `Self.assert…` helper taking `some ModelStorage`, so the
/// two backends are held to the same behavior rather than to two hand-written copies.
@Suite(.serialized) struct CompositeNestedTests {

    static let model = Model(entities: [
        EntityDescription(entity: Facility.self)
    ])

    static func facility(
        name: String,
        street: String,
        city: String? = "Springfield",
        latitude: Double,
        longitude: Double,
        billing: Address? = nil
    ) -> Facility {
        Facility(
            name: name,
            address: Address(
                street: street,
                city: city,
                location: Campground.LocationCoordinates(latitude: latitude, longitude: longitude)
            ),
            billingAddress: billing
        )
    }

    // MARK: - Shared assertions

    /// A nested composite survives a round trip with every level intact.
    static func assertRoundTrip(_ store: some ModelStorage) async throws {
        let facility = facility(
            name: "North",
            street: "1 Main",
            latitude: 34.51446212994721,
            longitude: -89.15318142250365
        )
        try await store.insert(facility)
        let fetched = try #require(try await store.fetch(Facility.self, for: facility.id))
        #expect(fetched == facility)
        #expect(fetched.address.street == "1 Main")
        #expect(fetched.address.city == "Springfield")
        // the innermost level keeps full floating point precision
        #expect(fetched.address.location.latitude == 34.51446212994721)
        #expect(fetched.address.location.longitude == -89.15318142250365)
    }

    /// The stored value is nested structure, not a flattened key space.
    static func assertStoredValueIsNested(_ store: some ModelStorage) async throws {
        let facility = facility(name: "North", street: "1 Main", latitude: 40.7, longitude: -74.0)
        try await store.insert(facility)
        let data = try #require(try await store.fetch(Facility.entityName, for: ObjectID(facility.id)))
        #expect(data.attributes["address"] == .composite([
            "street": .string("1 Main"),
            "city": .string("Springfield"),
            "location": .composite([
                "latitude": .double(40.7),
                "longitude": .double(-74.0)
            ])
        ]))
        // there is no flattened key for the nested element
        #expect(data.attributes["address.location"] == nil)
        #expect(data.attributes["address.location.latitude"] == nil)
    }

    /// A predicate can address an element two levels deep.
    static func assertNestedPredicate(_ store: some ModelStorage) async throws {
        let north = facility(name: "North", street: "1 Main", latitude: 40.7, longitude: -74.0)
        let south = facility(name: "South", street: "2 Oak", latitude: 25.8, longitude: -80.2)
        try await store.insert([try north.encode(), try south.encode()])
        let deep = try await store.fetch(
            Facility.self,
            predicate: "address.location.latitude" > 30
        )
        #expect(deep.map(\.name) == ["North"])
        // and one level deep, on the same composite
        let shallow = try await store.fetch(
            Facility.self,
            predicate: "address.street" == "2 Oak"
        )
        #expect(shallow.map(\.name) == ["South"])
    }

    /// A sort descriptor can address an element two levels deep.
    static func assertNestedSort(_ store: some ModelStorage) async throws {
        let north = facility(name: "North", street: "1 Main", latitude: 40.7, longitude: -74.0)
        let south = facility(name: "South", street: "2 Oak", latitude: 25.8, longitude: -80.2)
        try await store.insert([try north.encode(), try south.encode()])
        let ascending = try await store.fetch(
            Facility.self,
            sortDescriptors: [.init(property: "address.location.latitude", ascending: true)]
        )
        #expect(ascending.map(\.name) == ["South", "North"])
        let descending = try await store.fetch(
            Facility.self,
            sortDescriptors: [.init(property: "address.location.latitude", ascending: false)]
        )
        #expect(descending.map(\.name) == ["North", "South"])
    }

    /// An optional composite is absent as a whole, while a nested optional *element*
    /// is null within a composite that is itself present.
    static func assertNullHandling(_ store: some ModelStorage) async throws {
        let facility = facility(
            name: "North",
            street: "1 Main",
            city: nil,
            latitude: 40.7,
            longitude: -74.0
        )
        try await store.insert(facility)
        let fetched = try #require(try await store.fetch(Facility.self, for: facility.id))
        #expect(fetched.billingAddress == nil)
        #expect(fetched.address.city == nil)
        #expect(fetched.address.street == "1 Main")
        let data = try #require(try await store.fetch(Facility.entityName, for: ObjectID(facility.id)))
        // the absent composite is null as a whole, not a dictionary of nulls
        #expect(data.attributes["billingAddress"] == .null)
        // the absent element is null inside a composite that is present
        guard case let .composite(address)? = data.attributes["address"] else {
            Issue.record("Expected a composite address")
            return
        }
        #expect(address["city"] == .null)
        #expect(address["street"] == .string("1 Main"))
    }

    /// Both nested composites are independently addressable when both are populated.
    static func assertTwoNestedComposites(_ store: some ModelStorage) async throws {
        let facility = facility(
            name: "North",
            street: "1 Main",
            latitude: 40.7,
            longitude: -74.0,
            billing: Address(
                street: "PO Box 9",
                city: "Shelbyville",
                location: Campground.LocationCoordinates(latitude: 1.5, longitude: 2.5)
            )
        )
        try await store.insert(facility)
        let fetched = try #require(try await store.fetch(Facility.self, for: facility.id))
        #expect(fetched.address.location.latitude == 40.7)
        #expect(fetched.billingAddress?.location.latitude == 1.5)
        #expect(fetched.billingAddress?.street == "PO Box 9")
        // each is reachable by its own nested key path
        let matched = try await store.fetch(
            Facility.self,
            predicate: "billingAddress.location.latitude" == 1.5
        )
        #expect(matched.map(\.name) == ["North"])
    }

    /// Replacing a nested composite replaces it whole, at every level.
    static func assertNestedUpdate(_ store: some ModelStorage) async throws {
        var facility = facility(name: "North", street: "1 Main", latitude: 40.7, longitude: -74.0)
        try await store.insert(facility)
        facility.address.location = Campground.LocationCoordinates(latitude: 1, longitude: 2)
        facility.address.street = "3 Elm"
        try await store.insert(facility)
        let fetched = try #require(try await store.fetch(Facility.self, for: facility.id))
        #expect(fetched.address.street == "3 Elm")
        #expect(fetched.address.location == Campground.LocationCoordinates(latitude: 1, longitude: 2))
        // setting the optional composite back to nil clears it
        facility.billingAddress = nil
        try await store.insert(facility)
        let cleared = try #require(try await store.fetch(Facility.self, for: facility.id))
        #expect(cleared.billingAddress == nil)
    }

    // MARK: - In-memory store

    @Test func inMemoryRoundTrip() async throws {
        try await Self.assertRoundTrip(InMemoryModelStorage(model: Self.model))
    }

    @Test func inMemoryStoredValueIsNested() async throws {
        try await Self.assertStoredValueIsNested(InMemoryModelStorage(model: Self.model))
    }

    @Test func inMemoryNestedPredicate() async throws {
        try await Self.assertNestedPredicate(InMemoryModelStorage(model: Self.model))
    }

    @Test func inMemoryNestedSort() async throws {
        try await Self.assertNestedSort(InMemoryModelStorage(model: Self.model))
    }

    @Test func inMemoryNullHandling() async throws {
        try await Self.assertNullHandling(InMemoryModelStorage(model: Self.model))
    }

    @Test func inMemoryTwoNestedComposites() async throws {
        try await Self.assertTwoNestedComposites(InMemoryModelStorage(model: Self.model))
    }

    @Test func inMemoryNestedUpdate() async throws {
        try await Self.assertNestedUpdate(InMemoryModelStorage(model: Self.model))
    }

    // MARK: - CoreData

    #if canImport(CoreData)

    /// - Note: An explicit SQLite store, since CoreData refuses composite attributes
    /// in atomic (in-memory, XML, binary) stores.
    @available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
    static func makeCoreDataStore() throws -> PersistentContainerStorage {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("Nested-\(UUID()).sqlite")
        let description = NSPersistentStoreDescription(url: url)
        description.type = NSSQLiteStoreType
        description.shouldAddStoreAsynchronously = false
        return try PersistentContainerStorage(
            name: "Nested\(UUID())",
            model: Self.model,
            storeDescriptions: [description]
        )
    }

    @available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
    @Test func coreDataRoundTrip() async throws {
        try await Self.assertRoundTrip(try Self.makeCoreDataStore())
    }

    @available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
    @Test func coreDataStoredValueIsNested() async throws {
        try await Self.assertStoredValueIsNested(try Self.makeCoreDataStore())
    }

    @available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
    @Test func coreDataNestedPredicate() async throws {
        try await Self.assertNestedPredicate(try Self.makeCoreDataStore())
    }

    @available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
    @Test func coreDataNestedSort() async throws {
        try await Self.assertNestedSort(try Self.makeCoreDataStore())
    }

    @available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
    @Test func coreDataNullHandling() async throws {
        try await Self.assertNullHandling(try Self.makeCoreDataStore())
    }

    @available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
    @Test func coreDataTwoNestedComposites() async throws {
        try await Self.assertTwoNestedComposites(try Self.makeCoreDataStore())
    }

    @available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
    @Test func coreDataNestedUpdate() async throws {
        try await Self.assertNestedUpdate(try Self.makeCoreDataStore())
    }

    /// The nested element list reaches CoreData as a nested `NSCompositeAttributeDescription`.
    @available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
    @Test func coreDataNestedSchema() throws {
        let managedObjectModel = try NSManagedObjectModel(model: Self.model)
        let entity = try #require(managedObjectModel.entitiesByName["Facility"])
        let address = try #require(entity.attributesByName["address"] as? NSCompositeAttributeDescription)
        #expect(address.elements.count == 3)
        let location = try #require(address.elements.first { $0.name == "location" } as? NSCompositeAttributeDescription)
        #expect(location.elements.count == 2)
        #expect(location.elements.map(\.name).sorted() == ["latitude", "longitude"])
        // elements are optional at every level
        #expect(address.elements.allSatisfy { $0.isOptional })
        #expect(location.elements.allSatisfy { $0.isOptional })
        // and the whole tree round trips back
        #expect(AttributeType(attribute: address) == Address.attributeType)
    }

    #endif
}
