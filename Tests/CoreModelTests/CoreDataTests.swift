//
//  CoreDataTests.swift
//  
//
//  Created by Alsey Coleman Miller on 8/17/23.
//

#if canImport(CoreData)

import Foundation
import CoreData
import XCTest
import Predicate
@testable import CoreModel
@testable import CoreDataModel

final class CoreDataTests: XCTestCase {
    
    func testCoreData() async throws {
        
        let model = Model(entities: [
            EntityDescription(
                id: "Person",
                attributes: [
                    Attribute(
                        id: "name",
                        type: .string
                    )
                ],
                relationships: [
                    Relationship(
                        id: "events",
                        type: .toMany,
                        destinationEntity: "Event",
                        inverseRelationship: "people"
                    )
                ]
            ),
            EntityDescription(
                id: "Event",
                attributes: [
                    Attribute(
                        id: "name",
                        type: .string
                    ),
                    Attribute(
                        id: "date",
                        type: .date
                    )
                ],
                relationships: [
                    Relationship(
                        id: "people",
                        type: .toMany,
                        destinationEntity: "Person",
                        inverseRelationship: "events"
                    )
                ]
            ),
            ])
        
        let store = NSPersistentContainer(
            name: "Test\(UUID())",
            managedObjectModel: NSManagedObjectModel(model: model)
        )
        /*
        do {
            let event1 = ModelInstance(
                entity: "Event",
                id: "1",
                attributes: [:],
                relationships: [:]
            )
            store.insert()
            let event = try store("Event")
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
        }*/
    }
}

#endif
