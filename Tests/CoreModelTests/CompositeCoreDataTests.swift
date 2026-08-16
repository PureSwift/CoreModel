//
//  CompositeCoreDataTests.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 8/16/26.
//

#if canImport(CoreData)

import Foundation
import CoreData
import Testing
@testable import CoreModel
@testable import CoreDataModel

/// Composite attributes through the CoreData bridge.
///
/// - Note: CoreData supports composite attributes only in SQLite-backed stores, so
/// every store here is built with an explicit `NSSQLiteStoreType` description.
@Suite struct CompositeCoreDataTests {

    // MARK: - Schema

    @Test func attributeTypeConversion() throws {
        let type = Campground.LocationCoordinates.attributeType
        #expect(NSAttributeType(attributeType: type).rawValue == 2100)
        #expect(NSAttributeType.composite.rawValue == 2100)
        // the type alone can't carry elements, so this direction stays nil
        #expect(AttributeType(attributeType: .composite) == nil)
    }

    @available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
    @Test func compositeAttributeDescription() throws {
        let attribute = Attribute(id: "location", composite: Campground.LocationCoordinates.self)
        let description = try NSAttributeDescription.make(attribute: attribute)
        let composite = try #require(description as? NSCompositeAttributeDescription)
        #expect(composite.name == "location")
        #expect(composite.attributeType.rawValue == 2100)
        #expect(composite.elements.count == 2)
        #expect(composite.elements.map(\.name).sorted() == ["latitude", "longitude"])
        // every element must be optional, or saving raises a validation fault
        #expect(composite.elements.allSatisfy { $0.isOptional })
    }

    @available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
    @Test func nestedCompositeAttributeDescription() throws {
        let elements = [
            Attribute(id: "street", type: .string),
            Attribute(id: "location", composite: Campground.LocationCoordinates.self)
        ]
        let description = try NSAttributeDescription.make(attribute: Attribute(id: "address", elements: elements))
        let composite = try #require(description as? NSCompositeAttributeDescription)
        let nested = try #require(composite.elements.first { $0.name == "location" } as? NSCompositeAttributeDescription)
        #expect(nested.elements.count == 2)
    }

    @available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
    @Test func attributeDescriptionRoundTrip() throws {
        for type in [Campground.LocationCoordinates.attributeType, Campground.Schedule.attributeType] {
            let description = try NSAttributeDescription.make(attribute: Attribute(id: "value", type: type))
            #expect(AttributeType(attribute: description) == type)
        }
        // scalars round trip through the same initializer
        for type in AttributeType.scalarCases {
            let description = try NSAttributeDescription.make(attribute: Attribute(id: "value", type: type))
            #expect(AttributeType(attribute: description) == type)
        }
    }

    @Test func emptyCompositeThrows() throws {
        #expect(throws: CoreDataModelError.self) {
            try NSAttributeDescription.make(attribute: Attribute(id: "empty", elements: []))
        }
    }

    @available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
    @Test func managedObjectModelIncludesComposite() throws {
        // both entities, so the `units` relationship can resolve its inverse
        let model = try NSManagedObjectModel(model: Model(entities: [
            EntityDescription(entity: Campground.self),
            EntityDescription(entity: Campground.Unit.self)
        ]))
        let entity = try #require(model.entitiesByName["Campground"])
        let location = try #require(entity.attributesByName["location"])
        #expect(location is NSCompositeAttributeDescription)
        #expect(AttributeType(attribute: location) == Campground.LocationCoordinates.attributeType)
    }

    // MARK: - Value marshalling

    @Test func compositeToFoundation() throws {
        let value = AttributeValue.composite([
            "latitude": .double(40.7),
            "longitude": .double(-74.0),
            "label": .null
        ])
        let dictionary = try #require(value.toFoundation() as? NSDictionary)
        #expect(dictionary["latitude"] as? Double == 40.7)
        #expect(dictionary["longitude"] as? Double == -74.0)
        // null elements are omitted rather than stored as NSNull
        #expect(dictionary["label"] == nil)
        #expect(dictionary.count == 2)
    }

    @Test func compositeFromFoundation() throws {
        let elements = Campground.LocationCoordinates.attributeElements
        let decoded = try AttributeValue.composite(
            from: ["latitude": 40.7, "longitude": -74.0],
            elements: elements
        )
        #expect(decoded == ["latitude": .double(40.7), "longitude": .double(-74.0)])
        // a missing key and NSNull both decode as null, so the shape matches the schema
        let partial = try AttributeValue.composite(
            from: ["latitude": 40.7, "longitude": NSNull()],
            elements: elements
        )
        #expect(partial == ["latitude": .double(40.7), "longitude": .null])
        // an unknown stored key is ignored rather than mis-typed
        let extra = try AttributeValue.composite(
            from: ["latitude": 40.7, "longitude": -74.0, "altitude": 3.0],
            elements: elements
        )
        #expect(extra.count == 2)
    }

    @Test func keyPathExpression() throws {
        let expression = FetchRequest.Predicate.Expression.keyPath("location.latitude")
        #expect(expression.toFoundation().keyPath == "location.latitude")
    }

    // MARK: - SQLite round trip

    @available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
    private func makeStore() throws -> PersistentContainerStorage {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("Composite-\(UUID()).sqlite")
        let description = NSPersistentStoreDescription(url: url)
        description.type = NSSQLiteStoreType
        description.shouldAddStoreAsynchronously = false
        return try PersistentContainerStorage(
            name: "Composite\(UUID())",
            model: Model(entities: [
                EntityDescription(entity: Campground.self),
                EntityDescription(entity: Campground.Unit.self)
            ]),
            storeDescriptions: [description]
        )
    }

    private static func campground(
        name: String,
        latitude: Double,
        longitude: Double,
        start: UInt = 9,
        end: UInt = 17
    ) -> Campground {
        Campground(
            name: name,
            address: "\(name) Road",
            location: Campground.LocationCoordinates(latitude: latitude, longitude: longitude),
            descriptionText: name,
            officeHours: Campground.Schedule(start: start, end: end)
        )
    }

    @available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
    @Test func sqliteRoundTrip() async throws {
        let store = try makeStore()
        // high precision values double as a floating point fidelity check
        let campground = Self.campground(
            name: "North",
            latitude: 34.51446212994721,
            longitude: -89.15318142250365
        )
        try await store.insert(campground)
        let fetched = try await store.fetch(Campground.self, for: campground.id)
        #expect(fetched?.location.latitude == 34.51446212994721)
        #expect(fetched?.location.longitude == -89.15318142250365)
        #expect(fetched?.officeHours == Campground.Schedule(start: 9, end: 17))
        // the value is structured in the store, not a flattened string
        let data = try #require(try await store.fetch(Campground.entityName, for: ObjectID(campground.id)))
        #expect(data.attributes["location"] == .composite([
            "latitude": .double(34.51446212994721),
            "longitude": .double(-89.15318142250365)
        ]))
    }

    /// The load bearing claim: CoreData compiles a namespaced composite key path
    /// into the SQL it issues for a fetch request.
    @available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
    @Test func sqliteElementPredicate() async throws {
        let store = try makeStore()
        let north = Self.campground(name: "North", latitude: 40.7, longitude: -74.0)
        let south = Self.campground(name: "South", latitude: 25.8, longitude: -80.2)
        try await store.insert([try north.encode(), try south.encode()])
        let results = try await store.fetch(
            Campground.self,
            predicate: "location.latitude" > 30
        )
        #expect(results.map(\.name) == ["North"])
    }

    @available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
    @Test func sqliteElementSort() async throws {
        let store = try makeStore()
        let north = Self.campground(name: "North", latitude: 40.7, longitude: -74.0, start: 9)
        let south = Self.campground(name: "South", latitude: 25.8, longitude: -80.2, start: 6)
        try await store.insert([try north.encode(), try south.encode()])
        let results = try await store.fetch(
            Campground.self,
            sortDescriptors: [.init(property: "officeHours.start", ascending: true)]
        )
        #expect(results.map(\.name) == ["South", "North"])
    }

    @available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
    @Test func sqliteUpdateComposite() async throws {
        let store = try makeStore()
        var campground = Self.campground(name: "North", latitude: 40.7, longitude: -74.0)
        try await store.insert(campground)
        campground.officeHours = Campground.Schedule(start: 1, end: 2)
        campground.location = Campground.LocationCoordinates(latitude: 1, longitude: 2)
        try await store.insert(campground)
        let fetched = try await store.fetch(Campground.self, for: campground.id)
        #expect(fetched?.officeHours == Campground.Schedule(start: 1, end: 2))
        #expect(fetched?.location == Campground.LocationCoordinates(latitude: 1, longitude: 2))
    }
}

#endif
