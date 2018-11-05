//
//  CoreModelTests.swift
//  CoreModelTests
//
//  Created by Alsey Coleman Miller on 11/4/18.
//

import Foundation
import XCTest
import Predicate
@testable import CoreModel

final class CoreModelTests: XCTestCase {
    
    static let allTests = [
        ("testInMemoryStore", testInMemoryStore),
    ]
    
    func testInMemoryStore() {
        
        let model = Model(entities: [
            Entity(
                name: "Person",
                attributes: [
                    Attribute(
                        name: "name",
                        type: .string
                    )
                ],
                relationships: [
                    Relationship(
                        name: "events",
                        type: .toMany,
                        destinationEntity: "Event",
                        inverseRelationship: "people"
                    )
                ]
            ),
            Entity(
                name: "Event",
                attributes: [
                    Attribute(
                        name: "name",
                        type: .string
                    ),
                    Attribute(
                        name: "date",
                        type: .date
                    )
                ],
                relationships: [
                    Relationship(
                        name: "people",
                        type: .toMany,
                        destinationEntity: "Person",
                        inverseRelationship: "events"
                    )
                ]
            ),
            ])
        
        let store = InMemoryStore(model: model)
        
        do {
            let event = try store.create("Event")
            event.setAttribute(.string("Event 1"), for: "name")
            event.setAttribute(.date(Date()), for: "date")
            
            let person1 = try store.create("Person")
            person1.setAttribute(.string("Person1"), for: "name")
            
            let person2 = try store.create("Person")
            person2.setAttribute(.string("Person2"), for: "name")
            
            person1.setRelationship(.toMany([event]), for: "events")
            XCTAssertEqual(event.relationship(for: "people"), .toMany([person1]))
            XCTAssertEqual(person1.relationship(for: "events"), .toMany([event]))
            XCTAssertEqual(person2.relationship(for: "events"), .null)
            XCTAssertNotEqual(person2.relationship(for: "events"), .toMany([]))
            
            event.setRelationship(.toMany([person1, person2]), for: "people")
            XCTAssertEqual(event.relationship(for: "people"), .toMany([person1, person2]))
            XCTAssertEqual(person1.relationship(for: "events"), .toMany([event]))
            XCTAssertEqual(person2.relationship(for: "events"), .toMany([event]))
            
            event.setRelationship(.toMany([]), for: "people")
            XCTAssertEqual(event.relationship(for: "people"), .toMany([]))
            XCTAssertEqual(person1.relationship(for: "events"), .toMany([]))
            XCTAssertEqual(person2.relationship(for: "events"), .toMany([]))
            
            event.setRelationship(.toMany([person1]), for: "people")
            XCTAssertEqual(event.relationship(for: "people"), .toMany([person1]))
            XCTAssertEqual(person1.relationship(for: "events"), .toMany([event]))
            XCTAssertEqual(person2.relationship(for: "events"), .toMany([]))
            
            event.setRelationship(.toMany([person1, person2]), for: "people")
            XCTAssertEqual(person1.relationship(for: "events"), .toMany([event]))
            XCTAssertEqual(person2.relationship(for: "events"), .toMany([event]))
            store.delete(event)
            
            XCTAssert(event.isDeleted)
            XCTAssertFalse(person1.isDeleted)
            XCTAssertFalse(person2.isDeleted)
            XCTAssertEqual(person1.relationship(for: "events"), .toMany([]))
            XCTAssertEqual(person2.relationship(for: "events"), .toMany([]))
            
            XCTAssertEqual(try store.fetch(FetchRequest(entity: "Person")), [person1, person2])
            XCTAssertEqual(try store.fetch(FetchRequest(entity: "Event")), [event])
        }
        
        catch { XCTFail("\(error)") }
    }
}
