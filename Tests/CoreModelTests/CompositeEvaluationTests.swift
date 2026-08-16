//
//  CompositeEvaluationTests.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 8/16/26.
//

import Foundation
import Testing
@testable import CoreModel

/// Predicate and sort evaluation against composite attribute key paths.
@Suite struct CompositeEvaluationTests {

    private static func campground(
        id: ObjectID,
        latitude: Double,
        longitude: Double,
        start: UInt,
        end: UInt
    ) -> ModelData {
        ModelData(
            entity: Campground.entityName,
            id: id,
            attributes: [
                "name": .string("Camp \(id.rawValue)"),
                "location": .composite([
                    "latitude": .double(latitude),
                    "longitude": .double(longitude)
                ]),
                "officeHours": .composite([
                    "start": .int64(Int64(start)),
                    "end": .int64(Int64(end))
                ])
            ],
            relationships: [:]
        )
    }

    private let north = campground(id: "north", latitude: 40.7, longitude: -74.0, start: 9, end: 17)
    private let south = campground(id: "south", latitude: 25.8, longitude: -80.2, start: 7, end: 15)

    // MARK: - Key path evaluation

    @Test func elementKeyPath() {
        #expect(("location.latitude" > 30).evaluate(with: north))
        #expect(("location.latitude" > 30).evaluate(with: south) == false)
        #expect(("location.longitude" < -70).evaluate(with: north))
        #expect(("officeHours.start" == 9).evaluate(with: north))
    }

    @Test func wholeCompositeEquality() {
        let predicate = "location".compare(.equalTo, .attribute(.composite([
            "latitude": .double(40.7),
            "longitude": .double(-74.0)
        ])))
        #expect(predicate.evaluate(with: north))
        #expect(predicate.evaluate(with: south) == false)
    }

    @Test func nestedElementKeyPath() {
        let data = ModelData(
            entity: "Test",
            id: "1",
            attributes: [
                "address": .composite([
                    "street": .string("1 Main"),
                    "location": .composite([
                        "latitude": .double(40.7),
                        "longitude": .double(-74.0)
                    ])
                ])
            ],
            relationships: [:]
        )
        #expect(("address.location.latitude" > 30).evaluate(with: data))
        #expect(("address.location.latitude" > 50).evaluate(with: data) == false)
        #expect(("address.street" == "1 Main").evaluate(with: data))
    }

    @Test func unresolvableKeyPath() {
        // an element the composite doesn't declare
        #expect(("location.altitude" > 0).evaluate(with: north) == false)
        // descending into a scalar
        #expect(("name.length" > 0).evaluate(with: north) == false)
        // descending past a leaf
        #expect(("location.latitude.degrees" > 0).evaluate(with: north) == false)
        // an unresolvable path is null, matching a missing top-level key
        #expect("location.altitude".compare(.equalTo, .attribute(.null)).evaluate(with: north))
    }

    /// The root variable of a `Foundation.Predicate` converts to an empty key path,
    /// which previously reached `PropertyKey(rawValue: "")` and tripped its assertion.
    @Test func emptyKeyPath() {
        let expression = FetchRequest.Predicate.Expression.keyPath(PredicateKeyPath(keys: []))
        #expect(expression.evaluate(with: north, functions: [:]) == nil)
    }

    @Test func compositeIsNotOrderable() {
        let predicate = "location".compare(.lessThan, .attribute(.composite([
            "latitude": .double(99.0)
        ])))
        #expect(predicate.evaluate(with: north) == false)
    }

    // MARK: - Sorting

    @Test func sortByElement() {
        let all = [north, south]
        let ascending = all.sorted(by: [.init(property: "location.latitude", ascending: true)])
        #expect(ascending.map(\.id) == ["south", "north"])
        let descending = all.sorted(by: [.init(property: "location.latitude", ascending: false)])
        #expect(descending.map(\.id) == ["north", "south"])
        // and on a different composite
        let byHours = all.sorted(by: [.init(property: "officeHours.start", ascending: true)])
        #expect(byHours.map(\.id) == ["south", "north"])
    }

    @Test func sortByUnresolvableElementIsStable() {
        // uncomparable values fall through to the object identifier tiebreaker
        let sorted = [north, south].sorted(by: [.init(property: "location.altitude", ascending: true)])
        #expect(sorted.map(\.id) == ["north", "south"])
    }

    @available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
    @Test func sortComparatorByElement() {
        let comparator = FetchRequest.SortDescriptor(property: "location.latitude", ascending: true)
        #expect(comparator.compare(south, north) == .orderedAscending)
        #expect(comparator.compare(north, south) == .orderedDescending)
        #expect(comparator.compare(north, north) == .orderedSame)
    }

    /// A property whose name literally contains a dot still resolves directly, so
    /// existing models are unaffected by the key path convention.
    @Test func literalDottedPropertyNameWins() {
        let data = ModelData(
            entity: "Test",
            id: "1",
            attributes: [
                "location.latitude": .double(1),
                "location": .composite(["latitude": .double(2)])
            ],
            relationships: [:]
        )
        #expect(("location.latitude" == 1).evaluate(with: data))
        let sorted = [data].sorted(by: [.init(property: "location.latitude", ascending: true)])
        #expect(sorted.count == 1)
    }
}
