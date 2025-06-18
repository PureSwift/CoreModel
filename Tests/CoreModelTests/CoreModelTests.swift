//
//  CoreModelTests.swift
//  CoreModelTests
//
//  Created by Alsey Coleman Miller on 11/4/18.
//

import Foundation
import Testing
@testable import CoreModel

@Suite struct CoreModelTests {
    
    @Test func entityName() {
        
        #expect(Person.entityName == "Person")
        #expect(Event.entityName == "Event")
        #expect(Campground.entityName == "Campground")
        #expect(Campground.RentalUnit.entityName == "RentalUnit")
    }
    
    @Test func testPersonEntity() {
        validateEntityConformance(Person.self)
    }
    
    @Test func testEventEntity() {
        validateEntityConformance(Event.self)
    }
    
    @Test func testCampgroundEntity() {
        validateEntityConformance(Campground.self)
    }
    
    @Test func testRentalUnitEntity() {
        validateEntityConformance(Campground.RentalUnit.self)
    }
}

protocol EntityTestInfo {
    static var expectedEntityName: String { get }
    
    /// Key is attribute CodingKey string, Value is expected AttributeType
    static var expectedAttributes: [String: AttributeType] { get }
    
    /// Key is relationship CodingKey string, value is tuple of
    /// (relationship type, destination entity name, optional inverse relationship key string)
    static var expectedRelationships: [String: (type: RelationshipType, destinationEntity: String, inverseRelationshipKey: String?)] { get }
}

// MARK: - Generic Validator

extension CoreModelTests {
    
    func validateEntityConformance<E: Entity & EntityTestInfo>(_ entityType: E.Type) {
        
        #expect(E.entityName.description == E.expectedEntityName, "entityName mismatch for \(E.self)")
        
        // Validate attributes
        for (expectedKey, expectedType) in E.expectedAttributes {
            guard let actualType = E.attributes.first(where: { "\($0.key.stringValue)" == expectedKey })?.value else {
                Issue.record("Missing attribute '\(expectedKey)' in \(E.self)")
                return
            }
            #expect(actualType == expectedType, "Attribute '\(expectedKey)' type mismatch for \(E.self)")
        }
        
        // Validate relationships
        for (expectedKey, expectedRel) in E.expectedRelationships {
            guard let actualRel = E.relationships.first(where: { "\($0.key.stringValue)" == expectedKey })?.value else {
                Issue.record("Missing relationship '\(expectedKey)' in \(E.self)")
                return
            }
            #expect(actualRel.type == expectedRel.type, "Relationship '\(expectedKey)' type mismatch for \(E.self)")
            #expect(actualRel.destinationEntity.rawValue == expectedRel.destinationEntity, "Relationship '\(expectedKey)' destinationEntity mismatch for \(E.self)")
            if let expectedInverse = expectedRel.inverseRelationshipKey {
                #expect("\(actualRel.inverseRelationship)" == expectedInverse, "Relationship '\(expectedKey)' inverseRelationship mismatch for \(E.self)")
            }
        }
    }
}

// MARK: - EntityTestInfo Implementations

extension Person: EntityTestInfo {
    static var expectedEntityName: String { "Person" }
    static var expectedAttributes: [String : AttributeType] {
        [
            "name": .string,
            "created": .date,
            "age": .int16
        ]
    }
    static var expectedRelationships: [String : (type: RelationshipType, destinationEntity: String, inverseRelationshipKey: String?)] {
        [
            "events": (.toMany, "Event", "people")
        ]
    }
}

extension Event: EntityTestInfo {
    static var expectedEntityName: String { "Event" }
    static var expectedAttributes: [String : AttributeType] {
        [
            "name": .string,
            "date": .date
        ]
    }
    static var expectedRelationships: [String : (type: RelationshipType, destinationEntity: String, inverseRelationshipKey: String?)] {
        [
            "people": (.toMany, Person.entityName, "events")
        ]
    }
}

extension Campground: EntityTestInfo {
    static var expectedEntityName: String { "Campground" }
    static var expectedAttributes: [String : AttributeType] {
        [
            "name": .string,
            "created": .date,
            "updated": .date,
            "address": .string,
            "location": .string,
            "amenities": .string,
            "phoneNumber": .string,
            "descriptionText": .string,
            "timeZone": .int32,
            "notes": .string,
            "directions": .string,
            "officeHours": .string
        ]
    }
    static var expectedRelationships: [String : (type: RelationshipType, destinationEntity: String, inverseRelationshipKey: String?)] {
        [
            "units": (.toMany, "RentalUnit", "campground")
        ]
    }
}

extension Campground.RentalUnit: EntityTestInfo {
    static var expectedEntityName: String { "RentalUnit" }
    static var expectedAttributes: [String : AttributeType] {
        [
            "name": .string,
            "notes": .string,
            "amenities": .string,
            "checkout": .string
        ]
    }
    static var expectedRelationships: [String : (type: RelationshipType, destinationEntity: String, inverseRelationshipKey: String?)] {
        [
            "campground": (.toOne, "Campground", "units")
        ]
    }
}

