//
//  BatchInsertTests.swift
//
//
//  Created by Alsey Coleman Miller on 7/9/26.
//

#if canImport(CoreData)

import Foundation
import CoreData
import Testing
@testable import CoreModel
@testable import CoreDataModel

@Suite
struct BatchInsertTests {

    /// Synthetic catalog payload: many events sharing a small set of people through
    /// to-many relationships, duplicate values in the same batch, relationship targets
    /// appearing after the values that reference them, and an upsert pass over
    /// existing data.
    @available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
    @Test
    func batchInsert() async throws {

        let store = try await makeStore()

        // shared relationship targets
        var people = (0 ..< 20).map {
            Person(name: "Person \($0)", age: UInt(20 + $0))
        }
        // parents, each referencing 5 shared people
        let events = (0 ..< 200).map { index in
            Event(
                name: "Event \(index)",
                date: Date(timeIntervalSinceReferenceDate: TimeInterval(index)),
                people: (0 ..< 5).map { people[(index + $0) % people.count].id }
            )
        }
        // populate the inverse side so every value in the batch is self-consistent:
        // applying a value replaces its relationships wholesale (last write wins),
        // so a value encoding an empty inverse would sever links set by earlier values
        for index in people.indices {
            people[index].events = events
                .filter { $0.people.contains(people[index].id) }
                .map { $0.id }
        }

        // events first, so their relationship targets appear later in the batch;
        // people encoded twice, like shared objects repeated in a server payload
        var values = try events.map { try $0.encode() }
        values += try people.map { try $0.encode() }
        values += try people.map { try $0.encode() }

        try await store.insert(values)

        // duplicate values resolve to a single object
        let personCount = try await store.count(FetchRequest(entity: Person.entityName))
        let eventCount = try await store.count(FetchRequest(entity: Event.entityName))
        #expect(personCount == 20)
        #expect(eventCount == 200)

        // attributes and relationships round-trip
        let fetchedEvent = try #require(try await store.fetch(Event.self, for: events[0].id))
        #expect(fetchedEvent.name == "Event 0")
        #expect(Set(fetchedEvent.people) == Set(events[0].people))

        // inverse relationships are connected
        let fetchedPerson = try #require(try await store.fetch(Person.self, for: people[0].id))
        let expectedEvents = events.filter { $0.people.contains(people[0].id) }.map { $0.id }
        #expect(Set(fetchedPerson.events) == Set(expectedEvents))

        // re-inserting the batch updates objects in place
        var updatedEvents = events
        updatedEvents[42].name = "Updated Event"
        try await store.insert(try updatedEvents.map { try $0.encode() })
        let updatedCount = try await store.count(FetchRequest(entity: Event.entityName))
        #expect(updatedCount == 200)
        let updatedEvent = try #require(try await store.fetch(Event.self, for: events[42].id))
        #expect(updatedEvent.name == "Updated Event")

        // to-one relationships resolve to targets that appear later in the same batch
        let campgroundID = UUID()
        let officeHours = Campground.Schedule(start: 60 * 8, end: 60 * 18)
        let units = (0 ..< 5).map { index in
            Campground.Unit(
                campground: campgroundID,
                name: "A\(index)",
                checkout: officeHours
            )
        }
        let campground = Campground(
            id: campgroundID,
            name: "Fair Play RV Park",
            address: "243 Fisher Cove Rd, Fair Play, SC",
            location: .init(latitude: 34.51446212994721, longitude: -83.01371101951648),
            descriptionText: "Batch insert test campground",
            units: units.map { $0.id },
            officeHours: officeHours
        )
        var campgroundValues = try units.map { try $0.encode() }
        campgroundValues.append(try campground.encode())
        try await store.insert(campgroundValues)

        let fetchedCampground = try #require(try await store.fetch(Campground.self, for: campground.id))
        #expect(Set(fetchedCampground.units) == Set(units.map { $0.id }))
        let fetchedUnit = try #require(try await store.fetch(Campground.Unit.self, for: units[0].id))
        #expect(fetchedUnit.campground == campground.id)
    }

    /// The batched insert must scale roughly linearly with batch size.
    ///
    /// The previous per-object find-or-create degraded quadratically — a 10x larger
    /// batch cost ~100x more — because each fetch request evaluates its predicate
    /// against every pending unsaved object in the context. The prefetched object
    /// cache keeps the cost of a 10x larger batch at roughly 10x.
    @available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
    @Test
    func batchInsertScaling() async throws {
        // warm up the Core Data stack setup costs
        _ = try await measureInsert(count: 50)
        let small = try await measureInsert(count: 500)
        let large = try await measureInsert(count: 5_000)
        let ratio = large / small
        print("[BatchInsertTests] 500 objects: \(small)s, 5000 objects: \(large)s, ratio: \(ratio)")
        // linear scaling costs ~10x, the old quadratic behavior ~100x
        #expect(ratio < 40, "10x larger batch should cost roughly 10x, not \(ratio)x")
    }

    @available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
    private func measureInsert(count: Int) async throws -> TimeInterval {
        let store = try await makeStore()
        let people = (0 ..< 20).map {
            Person(name: "Person \($0)", age: 30)
        }
        let events = (0 ..< count).map { index in
            Event(
                name: "Event \(index)",
                date: Date(timeIntervalSinceReferenceDate: TimeInterval(index)),
                people: [people[index % people.count].id]
            )
        }
        var values = try people.map { try $0.encode() }
        values += try events.map { try $0.encode() }
        let start = Date()
        try await store.insert(values)
        return Date().timeIntervalSince(start)
    }

    @available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
    private func makeStore() async throws -> NSPersistentContainer {
        let model = Model(
            entities:
                Person.self,
                Event.self,
                Campground.self,
                Campground.Unit.self
        )
        let managedObjectModel = NSManagedObjectModel(model: model)
        let store = NSPersistentContainer(
            name: "Test\(UUID())",
            managedObjectModel: managedObjectModel
        )
        for try await store in store.loadPersistentStores() {
            _ = store
        }
        return store
    }
}

#endif
