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
            
            do {
                person1.setRelationship(.toMany([event]), for: "events")
                
                guard case let .toMany(attendees) = event.relationship(for: "people")
                    else { XCTFail(); return }
                
                XCTAssertEqual(attendees, [person1])
                
                guard case let .toMany(events) = person1.relationship(for: "events")
                    else { XCTFail(); return }
                
                XCTAssertEqual(events, [event])
            }
            
            do {
                event.setRelationship(.toMany([person1, person2]), for: "people")
                
                guard case let .toMany(attendees) = event.relationship(for: "people")
                    else { XCTFail(); return }
                
                XCTAssertEqual(attendees, [person1, person2])
                
                do {
                    guard case let .toMany(events) = person1.relationship(for: "events")
                        else { XCTFail(); return }
                    
                    XCTAssertEqual(events, [event])
                }
                
                do {
                    guard case let .toMany(events) = person2.relationship(for: "events")
                        else { XCTFail(); return }
                    
                    XCTAssertEqual(events, [event])
                }
            }
            
            do {
                event.setRelationship(.toMany([]), for: "people")
                
                guard case let .toMany(attendees) = event.relationship(for: "people")
                    else { XCTFail(); return }
                
                XCTAssertEqual(attendees, [])
                
                do {
                    guard case let .toMany(events) = person1.relationship(for: "events")
                        else { XCTFail(); return }
                    
                    XCTAssertEqual(events, [])
                }
                
                do {
                    guard case let .toMany(events) = person2.relationship(for: "events")
                        else { XCTFail(); return }
                    
                    XCTAssertEqual(events, [])
                }
            }
        }
        
        catch { XCTFail("\(error)") }
    }
}
