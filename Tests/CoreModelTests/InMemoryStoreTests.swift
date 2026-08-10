//
//  InMemoryStoreTests.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/21/26.
//

import Foundation
import Testing
@testable import CoreModel

@Suite struct InMemoryStoreTests {

    static let model = Model(entities: [
        EntityDescription(entity: Person.self),
        EntityDescription(entity: Event.self)
    ])

    @Test func insertAndFetch() async throws {
        let store = InMemoryModelStorage(model: Self.model)
        let person = Person(name: "Alice", age: 30)
        try await store.insert(person)
        let fetched = try await store.fetch(Person.self, for: person.id)
        #expect(fetched == person)
        // fetching an unknown identifier returns nil
        let missing = try await store.fetch(Person.self, for: UUID())
        #expect(missing == nil)
    }

    @Test func update() async throws {
        let store = InMemoryModelStorage(model: Self.model)
        var person = Person(name: "Alice", age: 30)
        try await store.insert(person)
        person.age = 31
        try await store.insert(person)
        let fetched = try await store.fetch(Person.self, for: person.id)
        #expect(fetched?.age == 31)
        let count = try await store.count(FetchRequest(entity: Person.entityName))
        #expect(count == 1)
    }

    @Test func batchInsert() async throws {
        let store = InMemoryModelStorage(model: Self.model)
        let people = (1...10).map { Person(name: "Person \($0)", age: UInt(20 + $0)) }
        try await store.insert(people.map { try $0.encode() })
        let count = try await store.count(FetchRequest(entity: Person.entityName))
        #expect(count == 10)
    }

    @Test func fetchRequest() async throws {
        let store = InMemoryModelStorage(model: Self.model)
        let people = (1...5).map { Person(name: "Person \($0)", age: UInt(20 + $0)) }
        try await store.insert(people.map { try $0.encode() })
        // predicate
        let adults: [Person] = try await store.fetch(
            Person.self,
            predicate: Person.CodingKeys.age > 22
        )
        #expect(adults.count == 3)
        #expect(adults.allSatisfy { $0.age > 22 })
        // sorting
        let sorted: [Person] = try await store.fetch(
            Person.self,
            sortDescriptors: [.init(property: "age", ascending: false)]
        )
        #expect(sorted.map { $0.age } == [25, 24, 23, 22, 21])
        // limit and offset
        let page: [Person] = try await store.fetch(
            Person.self,
            sortDescriptors: [.init(property: "age", ascending: true)],
            fetchLimit: 2,
            fetchOffset: 1
        )
        #expect(page.map { $0.age } == [22, 23])
        // count with predicate
        let count = try await store.count(Person.self, predicate: Person.CodingKeys.age <= 22)
        #expect(count == 2)
    }

    @Test func fetchID() async throws {
        let store = InMemoryModelStorage(model: Self.model)
        let person = Person(name: "Alice", age: 30)
        try await store.insert(person)
        let ids = try await store.fetchID(FetchRequest(entity: Person.entityName))
        #expect(ids == [ObjectID(person.id)])
    }

    @Test func delete() async throws {
        let store = InMemoryModelStorage(model: Self.model)
        let people = (1...3).map { Person(name: "Person \($0)", age: UInt(20 + $0)) }
        try await store.insert(people.map { try $0.encode() })
        try await store.delete(Person.self, for: people[0].id)
        var count = try await store.count(FetchRequest(entity: Person.entityName))
        #expect(count == 2)
        // batch delete
        try await store.delete(Person.entityName, for: people.map { ObjectID($0.id) })
        count = try await store.count(FetchRequest(entity: Person.entityName))
        #expect(count == 0)
    }

    @Test func relationshipPredicate() async throws {
        let store = InMemoryModelStorage(model: Self.model)
        let event = Event(name: "WWDC", date: Date())
        let attendee = Person(name: "Alice", age: 30, events: [event.id])
        let outsider = Person(name: "Bob", age: 25)
        try await store.insert([try attendee.encode(), try outsider.encode(), try event.encode()])
        let attendees: [Person] = try await store.fetch(
            Person.self,
            predicate: Person.CodingKeys.events.compare(.contains, .attribute(.string(event.id.uuidString)))
        )
        #expect(attendees == [attendee])
    }

    @Test func customFunction() async throws {
        let store = InMemoryModelStorage(model: Self.model)
        let stringLength = DatabaseFunction(name: "LENGTH", argumentCount: 1) { arguments in
            guard case let .string(value)? = arguments.first ?? nil else { return nil }
            return .int64(Int64(value.count))
        }
        try await store.register(function: stringLength)
        let people = [
            Person(name: "Jo", age: 20),
            Person(name: "Alexandra", age: 30)
        ]
        try await store.insert(people.map { try $0.encode() })
        let longNames: [Person] = try await store.fetch(
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

    @Test func modelValidation() async throws {
        let store = InMemoryModelStorage(model: Self.model)
        let person = Person(name: "Alice", age: 30)
        try await store.insert(person)
        let count = try await store.count(FetchRequest(entity: Person.entityName))
        #expect(count == 1)
        // unknown entities are rejected
        do {
            _ = try await store.fetch(FetchRequest(entity: "Unknown"))
            Issue.record("Expected an error")
        } catch CoreModelError.invalidEntity(let entity) {
            #expect(entity == "Unknown")
        }
    }
}
