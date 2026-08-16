//
//  CompositeStoreTests.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 8/16/26.
//

import Foundation
import Testing
@testable import CoreModel

/// Composite attributes through `InMemoryModelStorage`.
@Suite struct CompositeStoreTests {

    static let model = Model(entities: [
        EntityDescription(entity: Campground.self),
        EntityDescription(entity: Campground.Unit.self)
    ])

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

    @Test func roundTrip() async throws {
        let store = InMemoryModelStorage(model: Self.model)
        let campground = Self.campground(name: "North", latitude: 40.7, longitude: -74.0)
        try await store.insert(campground)
        let fetched = try await store.fetch(Campground.self, for: campground.id)
        #expect(fetched == campground)
        #expect(fetched?.location.latitude == 40.7)
        #expect(fetched?.officeHours == Campground.Schedule(start: 9, end: 17))
    }

    /// The stored value must be structured, not the flattened string it used to be.
    @Test func storedValueIsComposite() async throws {
        let store = InMemoryModelStorage(model: Self.model)
        let campground = Self.campground(name: "North", latitude: 40.7, longitude: -74.0)
        try await store.insert(campground)
        let data = try #require(try await store.fetch(Campground.entityName, for: ObjectID(campground.id)))
        #expect(data.attributes["location"] == .composite([
            "latitude": .double(40.7),
            "longitude": .double(-74.0)
        ]))
    }

    @Test func elementPredicate() async throws {
        let store = InMemoryModelStorage(model: Self.model)
        let north = Self.campground(name: "North", latitude: 40.7, longitude: -74.0)
        let south = Self.campground(name: "South", latitude: 25.8, longitude: -80.2)
        try await store.insert([try north.encode(), try south.encode()])
        let results = try await store.fetch(
            Campground.self,
            predicate: "location.latitude" > 30
        )
        #expect(results.map(\.name) == ["North"])
    }

    @Test func elementSort() async throws {
        let store = InMemoryModelStorage(model: Self.model)
        let north = Self.campground(name: "North", latitude: 40.7, longitude: -74.0, start: 9)
        let south = Self.campground(name: "South", latitude: 25.8, longitude: -80.2, start: 6)
        try await store.insert([try north.encode(), try south.encode()])
        let results = try await store.fetch(
            Campground.self,
            sortDescriptors: [.init(property: "officeHours.start", ascending: true)]
        )
        #expect(results.map(\.name) == ["South", "North"])
    }

    /// A composite is replaced whole on insert, rather than merged element-wise.
    @Test func updateReplacesComposite() async throws {
        let store = InMemoryModelStorage(model: Self.model)
        var campground = Self.campground(name: "North", latitude: 40.7, longitude: -74.0)
        try await store.insert(campground)
        campground.location = Campground.LocationCoordinates(latitude: 1, longitude: 2)
        try await store.insert(campground)
        let fetched = try await store.fetch(Campground.self, for: campground.id)
        #expect(fetched?.location == Campground.LocationCoordinates(latitude: 1, longitude: 2))
    }

    /// Reading normalizes a partially specified composite, so a declared element is
    /// never simply missing.
    @Test func normalizesPartialComposite() async throws {
        let store = InMemoryModelStorage(model: Self.model)
        let campground = Self.campground(name: "North", latitude: 40.7, longitude: -74.0)
        var data = try campground.encode()
        data.attributes["location"] = .composite(["latitude": .double(40.7)])
        try await store.insert(data)
        let fetched = try #require(try await store.fetch(Campground.entityName, for: data.id))
        #expect(fetched.attributes["location"] == .composite([
            "latitude": .double(40.7),
            "longitude": .null
        ]))
    }

    /// An absent composite normalizes to `.null`, not to a dictionary of nulls.
    @Test func normalizesAbsentComposite() async throws {
        let store = InMemoryModelStorage(model: Self.model)
        let campground = Self.campground(name: "North", latitude: 40.7, longitude: -74.0)
        var data = try campground.encode()
        data.attributes["location"] = nil
        try await store.insert(data)
        let fetched = try #require(try await store.fetch(Campground.entityName, for: data.id))
        #expect(fetched.attributes["location"] == .null)
    }
}
