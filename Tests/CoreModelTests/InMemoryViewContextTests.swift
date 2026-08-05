//
//  InMemoryViewContextTests.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/22/26.
//

import Foundation
import Testing
@testable import CoreModel

@MainActor
@Suite struct InMemoryViewContextTests {

    static let model = Model(entities: [
        EntityDescription(entity: Person.self),
        EntityDescription(entity: Event.self)
    ])

    @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
    @Test func insertAndFetch() throws {
        let context = InMemoryViewContext(model: Self.model)
        let person = Person(name: "Alice", age: 30)
        try context.insert(person.encode())
        let fetched = try context.fetch(Person.self, for: person.id)
        #expect(fetched == person)
        // fetching an unknown identifier returns nil
        let missing = try context.fetch(Person.self, for: UUID())
        #expect(missing == nil)
    }

    @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
    @Test func update() throws {
        let context = InMemoryViewContext(model: Self.model)
        var person = Person(name: "Alice", age: 30)
        try context.insert(person.encode())
        person.age = 31
        try context.insert(person.encode())
        let fetched = try context.fetch(Person.self, for: person.id)
        #expect(fetched?.age == 31)
        let count = try context.count(FetchRequest(entity: Person.entityName))
        #expect(count == 1)
    }

    @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
    @Test func batchInsert() throws {
        let context = InMemoryViewContext(model: Self.model)
        let people = (1...10).map { Person(name: "Person \($0)", age: UInt(20 + $0)) }
        try context.insert(people.map { try $0.encode() })
        let count = try context.count(FetchRequest(entity: Person.entityName))
        #expect(count == 10)
    }

    @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
    @Test func fetchRequest() throws {
        let context = InMemoryViewContext(model: Self.model)
        let people = (1...5).map { Person(name: "Person \($0)", age: UInt(20 + $0)) }
        try context.insert(people.map { try $0.encode() })
        // predicate
        let adults: [Person] = try context.fetch(
            Person.self,
            predicate: Person.CodingKeys.age > 22
        )
        #expect(adults.count == 3)
        #expect(adults.allSatisfy { $0.age > 22 })
        // sorting
        let sorted: [Person] = try context.fetch(
            Person.self,
            sortDescriptors: [.init(property: "age", ascending: false)]
        )
        #expect(sorted.map { $0.age } == [25, 24, 23, 22, 21])
        // limit and offset
        let page: [Person] = try context.fetch(
            Person.self,
            sortDescriptors: [.init(property: "age", ascending: true)],
            fetchLimit: 2,
            fetchOffset: 1
        )
        #expect(page.map { $0.age } == [22, 23])
        // count with predicate
        let count = try context.count(Person.self, predicate: Person.CodingKeys.age <= 22)
        #expect(count == 2)
    }

    @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
    @Test func fetchID() throws {
        let context = InMemoryViewContext(model: Self.model)
        let person = Person(name: "Alice", age: 30)
        try context.insert(person.encode())
        let ids = try context.fetchID(FetchRequest(entity: Person.entityName))
        #expect(ids == [ObjectID(person.id)])
    }

    @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
    @Test func delete() throws {
        let context = InMemoryViewContext(model: Self.model)
        let people = (1...3).map { Person(name: "Person \($0)", age: UInt(20 + $0)) }
        try context.insert(people.map { try $0.encode() })
        try context.delete(Person.entityName, for: ObjectID(people[0].id))
        var count = try context.count(FetchRequest(entity: Person.entityName))
        #expect(count == 2)
        // batch delete
        try context.delete(Person.entityName, for: people.map { ObjectID($0.id) })
        count = try context.count(FetchRequest(entity: Person.entityName))
        #expect(count == 0)
    }

    @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
    @Test func relationshipPredicate() throws {
        let context = InMemoryViewContext(model: Self.model)
        let event = Event(name: "WWDC", date: Date())
        let attendee = Person(name: "Alice", age: 30, events: [event.id])
        let outsider = Person(name: "Bob", age: 25)
        try context.insert([try attendee.encode(), try outsider.encode(), try event.encode()])
        let attendees: [Person] = try context.fetch(
            Person.self,
            predicate: Person.CodingKeys.events.compare(.contains, .attribute(.string(event.id.uuidString)))
        )
        #expect(attendees == [attendee])
    }

    @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
    @Test func customFunction() throws {
        let context = InMemoryViewContext(model: Self.model)
        let stringLength = DatabaseFunction(name: "LENGTH", argumentCount: 1) { arguments in
            guard case let .string(value)? = arguments.first ?? nil else { return nil }
            return .int64(Int64(value.count))
        }
        context.register(function: stringLength)
        let people = [
            Person(name: "Jo", age: 20),
            Person(name: "Alexandra", age: 30)
        ]
        try context.insert(people.map { try $0.encode() })
        let longNames: [Person] = try context.fetch(
            Person.self,
            predicate: .comparison(
                .init(
                    left: .function(.init(name: "LENGTH", arguments: [.keyPath("name")])),
                    right: .attribute(.int64(5)),
                    type: .greaterThan
                )
            )
        )
        #expect(longNames.map { $0.name } == ["Alexandra"])
    }

    @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
    @Test func sharedDataWithStore() async throws {
        let store = InMemoryModelStorage(model: Self.model)
        let context = store.viewContext
        // the same cached instance is returned on every access
        #expect(context === store.viewContext)
        // objects inserted through the store are visible to the view context
        let alice = Person(name: "Alice", age: 30)
        try await store.insert(alice)
        #expect(try context.fetch(Person.self, for: alice.id) == alice)
        #expect(try context.count(FetchRequest(entity: Person.entityName)) == 1)
        // objects inserted through the view context are visible to the store
        let bob = Person(name: "Bob", age: 25)
        try context.insert(bob.encode())
        let fetchedByStore = try await store.fetch(Person.self, for: bob.id)
        #expect(fetchedByStore == bob)
        // deletes propagate as well
        try await store.delete(Person.self, for: alice.id)
        #expect(try context.fetch(Person.self, for: alice.id) == nil)
        #expect(try context.count(FetchRequest(entity: Person.entityName)) == 1)
    }

    @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
    @Test func concurrentAccessWithStore() async throws {
        let store = InMemoryModelStorage(model: Self.model)
        let context = store.viewContext
        let people = (0 ..< 100).map { Person(name: "Person \($0)", age: UInt($0)) }
        // writers run on the store's actor while this main-actor task reads the same
        // backing, so the two isolation domains genuinely overlap
        async let inserts: Void = withThrowingTaskGroup(of: Void.self) { group in
            for person in people {
                group.addTask {
                    try await store.insert(person)
                }
            }
            try await group.waitForAll()
        }
        for _ in 0 ..< 100 {
            _ = try context.count(FetchRequest(entity: Person.entityName))
        }
        try await inserts
        let count = try context.count(FetchRequest(entity: Person.entityName))
        #expect(count == 100)
    }

    @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
    @Test func modelValidation() throws {
        let context = InMemoryViewContext(model: Self.model)
        let person = Person(name: "Alice", age: 30)
        try context.insert(person.encode())
        let count = try context.count(FetchRequest(entity: Person.entityName))
        #expect(count == 1)
        // unknown entities are rejected
        do {
            _ = try context.fetch(FetchRequest(entity: "Unknown"))
            Issue.record("Expected an error")
        } catch CoreModelError.invalidEntity(let entity) {
            #expect(entity == "Unknown")
        }
    }
}
