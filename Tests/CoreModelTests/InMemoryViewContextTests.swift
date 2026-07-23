//
//  InMemoryViewContextTests.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/22/26.
//

import Foundation
import XCTest
@testable import CoreModel

@MainActor
final class InMemoryViewContextTests: XCTestCase {

    static let model = Model(entities: [
        EntityDescription(entity: Person.self),
        EntityDescription(entity: Event.self)
    ])

    func testInsertAndFetch() throws {
        let context = InMemoryViewContext(model: Self.model)
        let person = Person(name: "Alice", age: 30)
        try context.insert(person.encode())
        let fetched = try context.fetch(Person.self, for: person.id)
        XCTAssertEqual(fetched, person)
        // fetching an unknown identifier returns nil
        let missing = try context.fetch(Person.self, for: UUID())
        XCTAssertNil(missing)
    }

    func testUpdate() throws {
        let context = InMemoryViewContext(model: Self.model)
        var person = Person(name: "Alice", age: 30)
        try context.insert(person.encode())
        person.age = 31
        try context.insert(person.encode())
        let fetched = try context.fetch(Person.self, for: person.id)
        XCTAssertEqual(fetched?.age, 31)
        let count = try context.count(FetchRequest(entity: Person.entityName))
        XCTAssertEqual(count, 1)
    }

    func testBatchInsert() throws {
        let context = InMemoryViewContext(model: Self.model)
        let people = (1...10).map { Person(name: "Person \($0)", age: UInt(20 + $0)) }
        try context.insert(people.map { try $0.encode() })
        let count = try context.count(FetchRequest(entity: Person.entityName))
        XCTAssertEqual(count, 10)
    }

    func testFetchRequest() throws {
        let context = InMemoryViewContext(model: Self.model)
        let people = (1...5).map { Person(name: "Person \($0)", age: UInt(20 + $0)) }
        try context.insert(people.map { try $0.encode() })
        // predicate
        let adults: [Person] = try context.fetch(
            Person.self,
            predicate: Person.CodingKeys.age > 22
        )
        XCTAssertEqual(adults.count, 3)
        XCTAssert(adults.allSatisfy { $0.age > 22 })
        // sorting
        let sorted: [Person] = try context.fetch(
            Person.self,
            sortDescriptors: [.init(property: "age", ascending: false)]
        )
        XCTAssertEqual(sorted.map { $0.age }, [25, 24, 23, 22, 21])
        // limit and offset
        let page: [Person] = try context.fetch(
            Person.self,
            sortDescriptors: [.init(property: "age", ascending: true)],
            fetchLimit: 2,
            fetchOffset: 1
        )
        XCTAssertEqual(page.map { $0.age }, [22, 23])
        // count with predicate
        let count = try context.count(Person.self, predicate: Person.CodingKeys.age <= 22)
        XCTAssertEqual(count, 2)
    }

    func testFetchID() throws {
        let context = InMemoryViewContext(model: Self.model)
        let person = Person(name: "Alice", age: 30)
        try context.insert(person.encode())
        let ids = try context.fetchID(FetchRequest(entity: Person.entityName))
        XCTAssertEqual(ids, [ObjectID(person.id)])
    }

    func testDelete() throws {
        let context = InMemoryViewContext(model: Self.model)
        let people = (1...3).map { Person(name: "Person \($0)", age: UInt(20 + $0)) }
        try context.insert(people.map { try $0.encode() })
        try context.delete(Person.entityName, for: ObjectID(people[0].id))
        var count = try context.count(FetchRequest(entity: Person.entityName))
        XCTAssertEqual(count, 2)
        // batch delete
        try context.delete(Person.entityName, for: people.map { ObjectID($0.id) })
        count = try context.count(FetchRequest(entity: Person.entityName))
        XCTAssertEqual(count, 0)
    }

    func testRelationshipPredicate() throws {
        let context = InMemoryViewContext(model: Self.model)
        let event = Event(name: "WWDC", date: Date())
        let attendee = Person(name: "Alice", age: 30, events: [event.id])
        let outsider = Person(name: "Bob", age: 25)
        try context.insert([try attendee.encode(), try outsider.encode(), try event.encode()])
        let attendees: [Person] = try context.fetch(
            Person.self,
            predicate: Person.CodingKeys.events.compare(.contains, .attribute(.string(event.id.uuidString)))
        )
        XCTAssertEqual(attendees, [attendee])
    }

    func testCustomFunction() throws {
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
        XCTAssertEqual(longNames.map { $0.name }, ["Alexandra"])
    }

    func testModelValidation() throws {
        let context = InMemoryViewContext(model: Self.model)
        let person = Person(name: "Alice", age: 30)
        try context.insert(person.encode())
        let count = try context.count(FetchRequest(entity: Person.entityName))
        XCTAssertEqual(count, 1)
        // unknown entities are rejected
        do {
            _ = try context.fetch(FetchRequest(entity: "Unknown"))
            XCTFail("Expected an error")
        } catch CoreModelError.invalidEntity(let entity) {
            XCTAssertEqual(entity, "Unknown")
        }
    }
}
