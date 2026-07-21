//
//  InMemoryStoreTests.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/21/26.
//

import Foundation
import XCTest
@testable import CoreModel

final class InMemoryStoreTests: XCTestCase {

    func testInsertAndFetch() async throws {
        let store = InMemoryModelStorage()
        let person = Person(name: "Alice", age: 30)
        try await store.insert(person)
        let fetched = try await store.fetch(Person.self, for: person.id)
        XCTAssertEqual(fetched, person)
        // fetching an unknown identifier returns nil
        let missing = try await store.fetch(Person.self, for: UUID())
        XCTAssertNil(missing)
    }

    func testUpdate() async throws {
        let store = InMemoryModelStorage()
        var person = Person(name: "Alice", age: 30)
        try await store.insert(person)
        person.age = 31
        try await store.insert(person)
        let fetched = try await store.fetch(Person.self, for: person.id)
        XCTAssertEqual(fetched?.age, 31)
        let count = try await store.count(FetchRequest(entity: Person.entityName))
        XCTAssertEqual(count, 1)
    }

    func testBatchInsert() async throws {
        let store = InMemoryModelStorage()
        let people = (1...10).map { Person(name: "Person \($0)", age: UInt(20 + $0)) }
        try await store.insert(people.map { try $0.encode() })
        let count = try await store.count(FetchRequest(entity: Person.entityName))
        XCTAssertEqual(count, 10)
    }

    func testFetchRequest() async throws {
        let store = InMemoryModelStorage()
        let people = (1...5).map { Person(name: "Person \($0)", age: UInt(20 + $0)) }
        try await store.insert(people.map { try $0.encode() })
        // predicate
        let adults: [Person] = try await store.fetch(
            Person.self,
            predicate: Person.CodingKeys.age > 22
        )
        XCTAssertEqual(adults.count, 3)
        XCTAssert(adults.allSatisfy { $0.age > 22 })
        // sorting
        let sorted: [Person] = try await store.fetch(
            Person.self,
            sortDescriptors: [.init(property: "age", ascending: false)]
        )
        XCTAssertEqual(sorted.map { $0.age }, [25, 24, 23, 22, 21])
        // limit and offset
        let page: [Person] = try await store.fetch(
            Person.self,
            sortDescriptors: [.init(property: "age", ascending: true)],
            fetchLimit: 2,
            fetchOffset: 1
        )
        XCTAssertEqual(page.map { $0.age }, [22, 23])
        // count with predicate
        let count = try await store.count(Person.self, predicate: Person.CodingKeys.age <= 22)
        XCTAssertEqual(count, 2)
    }

    func testFetchID() async throws {
        let store = InMemoryModelStorage()
        let person = Person(name: "Alice", age: 30)
        try await store.insert(person)
        let ids = try await store.fetchID(FetchRequest(entity: Person.entityName))
        XCTAssertEqual(ids, [ObjectID(person.id)])
    }

    func testDelete() async throws {
        let store = InMemoryModelStorage()
        let people = (1...3).map { Person(name: "Person \($0)", age: UInt(20 + $0)) }
        try await store.insert(people.map { try $0.encode() })
        try await store.delete(Person.self, for: people[0].id)
        var count = try await store.count(FetchRequest(entity: Person.entityName))
        XCTAssertEqual(count, 2)
        // batch delete
        try await store.delete(Person.entityName, for: people.map { ObjectID($0.id) })
        count = try await store.count(FetchRequest(entity: Person.entityName))
        XCTAssertEqual(count, 0)
    }

    func testRelationshipPredicate() async throws {
        let store = InMemoryModelStorage()
        let event = Event(name: "WWDC", date: Date())
        let attendee = Person(name: "Alice", age: 30, events: [event.id])
        let outsider = Person(name: "Bob", age: 25)
        try await store.insert([try attendee.encode(), try outsider.encode(), try event.encode()])
        let attendees: [Person] = try await store.fetch(
            Person.self,
            predicate: Person.CodingKeys.events.compare(.contains, .attribute(.string(event.id.uuidString)))
        )
        XCTAssertEqual(attendees, [attendee])
    }

    func testCustomFunction() async throws {
        let store = InMemoryModelStorage()
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
        XCTAssertEqual(longNames.map { $0.name }, ["Alexandra"])
    }

    func testModelValidation() async throws {
        let model = Model(entities: [EntityDescription(entity: Person.self)])
        let store = InMemoryModelStorage(model: model)
        let person = Person(name: "Alice", age: 30)
        try await store.insert(person)
        let count = try await store.count(FetchRequest(entity: Person.entityName))
        XCTAssertEqual(count, 1)
        // unknown entities are rejected
        do {
            _ = try await store.fetch(FetchRequest(entity: "Unknown"))
            XCTFail("Expected an error")
        } catch CoreModelError.invalidEntity(let entity) {
            XCTAssertEqual(entity, "Unknown")
        }
    }
}
