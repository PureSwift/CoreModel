//
//  KeyPathTraversalTests.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 8/16/26.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif
import Testing
@testable import CoreModel

/// Key paths that traverse a relationship (e.g. `events.name`), which `ALL`/`ANY`
/// comparisons rely on and CoreData resolves natively.
@Suite struct KeyPathTraversalTests {

    struct Fixture {

        static let wwdc = ModelData(
            entity: "Event",
            id: ObjectID(rawValue: "wwdc"),
            attributes: ["name": .string("WWDC"), "attendance": .int64(5000)]
        )

        static let other = ModelData(
            entity: "Event",
            id: ObjectID(rawValue: "other"),
            attributes: ["name": .string("Other"), "attendance": .int64(10)]
        )

        /// Attends both events.
        static let alice = ModelData(
            entity: "Person",
            id: ObjectID(rawValue: "alice"),
            attributes: ["name": .string("Alice")],
            relationships: [
                "events": .toMany([wwdc.id, other.id]),
                "favorite": .toOne(wwdc.id)
            ]
        )

        /// Attends only the non-WWDC event.
        static let bob = ModelData(
            entity: "Person",
            id: ObjectID(rawValue: "bob"),
            attributes: ["name": .string("Bob")],
            relationships: [
                "events": .toMany([other.id]),
                "favorite": .toOne(other.id)
            ]
        )

        /// Attends nothing.
        static let carol = ModelData(
            entity: "Person",
            id: ObjectID(rawValue: "carol"),
            attributes: ["name": .string("Carol")],
            relationships: ["events": .toMany([])]
        )

        static let all = [alice, bob, carol, wwdc, other]
    }

    @Test func anyModifier() {

        // ANY events.name == "WWDC"
        let predicate = "events.name".compare(.any, .equalTo, [], .attribute(.string("WWDC")))
        let request = FetchRequest(entity: "Person", predicate: predicate)
        #expect(request.evaluate(Fixture.all).map(\.id.rawValue) == ["alice"])
    }

    @Test func allModifier() {

        // ALL events.name == "Other"
        let predicate = "events.name".compare(.all, .equalTo, [], .attribute(.string("Other")))
        let request = FetchRequest(entity: "Person", predicate: predicate)
        // Carol has no events, so the comparison holds vacuously, as it does in CoreData
        #expect(request.evaluate(Fixture.all).map(\.id.rawValue) == ["bob", "carol"])
    }

    @Test func toOneTraversal() {

        // a to-one relationship resolves to a single value, no modifier needed
        let predicate = FetchRequest.Predicate.comparison(.init(
            left: .keyPath("favorite.name"),
            right: .attribute(.string("WWDC")),
            type: .equalTo
        ))
        let request = FetchRequest(entity: "Person", predicate: predicate)
        #expect(request.evaluate(Fixture.all).map(\.id.rawValue) == ["alice"])
    }

    @Test func numericTraversal() {

        // ANY events.attendance > 1000
        let predicate = "events.attendance".compare(.any, .greaterThan, [], .attribute(.int64(1000)))
        let request = FetchRequest(entity: "Person", predicate: predicate)
        #expect(request.evaluate(Fixture.all).map(\.id.rawValue) == ["alice"])
    }

    @Test func nullRelationship() {

        // a null relationship has nothing to traverse into
        let dave = ModelData(
            entity: "Person",
            id: ObjectID(rawValue: "dave"),
            attributes: ["name": .string("Dave")],
            relationships: ["events": .null, "favorite": .null]
        )
        let objects = Fixture.all + [dave]
        let any = FetchRequest(entity: "Person", predicate: "events.name".compare(.any, .equalTo, [], .attribute(.string("WWDC"))))
        #expect(any.evaluate(objects).map(\.id.rawValue) == ["alice"])
        let toOne = FetchRequest(entity: "Person", predicate: FetchRequest.Predicate.comparison(.init(
            left: .keyPath("favorite.name"),
            right: .attribute(.string("WWDC")),
            type: .equalTo
        )))
        #expect(toOne.evaluate(objects).map(\.id.rawValue) == ["alice"])
    }

    @Test func modifierOnNonCollection() {

        // an ALL/ANY modifier on a plain attribute falls back to a direct comparison
        let predicate = "name".compare(.any, .equalTo, [], .attribute(.string("Alice")))
        let request = FetchRequest(entity: "Person", predicate: predicate)
        #expect(request.evaluate(Fixture.all).map(\.id.rawValue) == ["alice"])
    }

    @Test func missingRelationshipProperty() {

        // a key path whose leading key isn't a relationship doesn't resolve
        let predicate = "name.length".compare(.any, .equalTo, [], .attribute(.int64(5)))
        let request = FetchRequest(entity: "Person", predicate: predicate)
        #expect(request.evaluate(Fixture.all).isEmpty)
    }

    @Test func unresolvedRelatedObjects() {

        // without the related objects, a traversing key path can't resolve
        let predicate = "events.name".compare(.any, .equalTo, [], .attribute(.string("WWDC")))
        let request = FetchRequest(entity: "Person", predicate: predicate)
        #expect(request.evaluate([Fixture.alice, Fixture.bob]).isEmpty)
    }

    @Test func inMemoryStorage() throws {

        // the same traversal through the in-memory store, which holds every entity
        let model = Model(entities: Person.self, Event.self)
        let storage = InMemoryStorage(model: model)
        let wwdc = Event(name: "WWDC", date: Date())
        let other = Event(name: "Other", date: Date())
        try storage.insert([wwdc.encode(), other.encode()])
        let alice = Person(name: "Alice", age: 30, events: [wwdc.id, other.id])
        let bob = Person(name: "Bob", age: 17, events: [other.id])
        try storage.insert([alice.encode(), bob.encode()])

        let anyRequest = FetchRequest(
            entity: Person.entityName,
            predicate: "events.name".compare(.any, .equalTo, [], .attribute(.string("WWDC")))
        )
        #expect(try storage.fetch(anyRequest).map { $0.attributes["name"] } == [.string("Alice")])

        let allRequest = FetchRequest(
            entity: Person.entityName,
            predicate: "events.name".compare(.all, .equalTo, [], .attribute(.string("Other")))
        )
        #expect(try storage.fetch(allRequest).map { $0.attributes["name"] } == [.string("Bob")])
    }

    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    @Test func foundationPredicate() throws {

        // the same traversals, built with the #Predicate macro
        let any = try FetchRequest.Predicate(#Predicate<PersonRecord> { $0.events.contains { $0.name == "WWDC" } })
        #expect(FetchRequest(entity: "Person", predicate: any).evaluate(Fixture.all).map(\.id.rawValue) == ["alice"])

        let all = try FetchRequest.Predicate(#Predicate<PersonRecord> { $0.events.allSatisfy { $0.name == "Other" } })
        #expect(FetchRequest(entity: "Person", predicate: all).evaluate(Fixture.all).map(\.id.rawValue) == ["bob", "carol"])

        let toOne = try FetchRequest.Predicate(#Predicate<PersonRecord> { $0.favorite.name == "WWDC" })
        #expect(FetchRequest(entity: "Person", predicate: toOne).evaluate(Fixture.all).map(\.id.rawValue) == ["alice"])
    }

    /// Mirrors the `Person` fixture for `#Predicate` conversion.
    struct PersonRecord {

        var name: String
        var events: [EventRecord]
        var favorite: EventRecord
    }

    /// Mirrors the `Event` fixture for `#Predicate` conversion.
    struct EventRecord {

        var name: String
        var attendance: Int
    }
}
