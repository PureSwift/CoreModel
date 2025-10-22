//
//  NSPredicateTests.swift
//  PredicateTests
//
//  Created by Alsey Coleman Miller on 4/2/17.
//  Copyright © 2017 PureSwift. All rights reserved.
//

#if canImport(Darwin)
import Foundation
import Testing
@testable import CoreModel
@testable import CoreDataModel

@Suite struct NSPredicateTests {
    
    @Test func description() {
        
        #expect((.keyPath("name") == .attribute(.string("Coleman"))).description == NSPredicate(format: "name == \"Coleman\"").description)
        #expect(((.keyPath("name") != .attribute(.null)) as FetchRequest.Predicate).description == NSPredicate(format: "name != nil").description)
        #expect((!(.keyPath("name") == .attribute(.null))).description == NSPredicate(format: "NOT name == nil").description)
    }
    
    @Test func comparison() {
        
        let predicate: FetchRequest.Predicate = #keyPath(PersonObject.id) > Int64(0)
            && (#keyPath(PersonObject.name)).compare(.notEqualTo, .attribute(.null))
            && (#keyPath(PersonObject.id)) != Int64(99)
            && (#keyPath(PersonObject.id)) == Int64(1)
            && (#keyPath(PersonObject.name)).compare(.beginsWith, .attribute(.string("C")))
            && (#keyPath(PersonObject.name)).compare(.contains, [.diacriticInsensitive, .caseInsensitive], .attribute(.string("COLE")))
        
        let converted = predicate.toFoundation()
        
        print(predicate)
        print(converted)
        
        #expect(predicate.description == converted.description)
        #expect(converted.evaluate(with: PersonObject(id: 1, name: "Coléman")))
    }
    
    @Test func predicateFilter() {
        
        let events = [
            EventObject(
                id: 100,
                name: "Awesome Event",
                start: Date(timeIntervalSince1970: 0),
                speakers: [
                    PersonObject(
                        id: 1,
                        name: "Alsey Coleman Miller"
                    )
            ]),
            EventObject(
                id: 200,
                name: "Second Event",
                start: Date(timeIntervalSince1970: 60 * 60 * 2),
                speakers: [
                    PersonObject(
                        id: 2,
                        name: "John Apple"
                    )
            ])
        ]
        
        let now = Date()
        
        let predicate: FetchRequest.Predicate = (#keyPath(EventObject.name)).compare(.matches, [.caseInsensitive], .attribute(.string(#"\w+ event"#)))
            && (#keyPath(EventObject.start)) < now
            && ("speakers.@count") > 0
        
        let nsPredicate = predicate.toFoundation()
        
        print(predicate)
        print(nsPredicate)
        
        #expect((events as NSArray).filtered(using: nsPredicate).count == events.count)
    }
    
    @Test func predicateAggregate() {
        
        let events = [
            EventObject(
                id: 1,
                name: "Event 1",
                start: Date(timeIntervalSince1970: 0),
                speakers: [
                    PersonObject(
                        id: 1,
                        name: "Alsey Coleman Miller"
                    )
            ]),
            EventObject(
                id: 2,
                name: "Event 2",
                start: Date(timeIntervalSince1970: 60 * 60 * 2),
                speakers: [
                    PersonObject(
                        id: 2,
                        name: "John Apple"
                    )
            ]),
            EventObject(
                id: 3,
                name: "Event 3",
                start: Date(timeIntervalSince1970: 60 * 60 * 4),
                speakers: [
                    PersonObject(
                        id: 1,
                        name: "Alsey Coleman Miller"
                    ),
                    PersonObject(
                        id: 2,
                        name: "John Apple"
                    )
            ])
        ]
        
        let now = Date()
        
        let predicate: FetchRequest.Predicate = (#keyPath(EventObject.name)).compare(.matches, [.caseInsensitive], .attribute(.string(#"event \d"#))) && [
            (#keyPath(EventObject.start)) < now,
            ("speakers.@count") > 0
            ]
        
        let nsPredicate = predicate.toFoundation()
        
        print(predicate)
        print(nsPredicate)
        
        #expect((events as NSArray).filtered(using: nsPredicate).count == events.count)
    }
    
    @Test func predicateContains() throws {
        
        let attributes = AttributesObject()
        attributes.data = Data()
        attributes.numbers = [0,1,2,3]
        attributes.strings = ["1", "2", "3"]
        
        let predicate: FetchRequest.Predicate = (#keyPath(AttributesObject.string)).compare(.equalTo, .attribute(.null))
            && (#keyPath(AttributesObject.data)).compare(.notEqualTo, .attribute(.null))
            && (#keyPath(AttributesObject.numbers)).compare(.contains, .attribute(.int16(1)))
            && (#keyPath(AttributesObject.strings)).compare(.contains, .attribute(.string("1")))
        
        let nsPredicate = predicate.toFoundation()
        
        print(predicate)
        print(nsPredicate)
        
        #expect(predicate.description == nsPredicate.description, "Invalid description")
        nsPredicate.evaluate(with: attributes)
    }
}

// MARK: - Supporting Types

@objc(Person)
class PersonObject: NSObject {
    
    @objc var id: Int
    @objc var name: String
    
    init(id: Int, name: String) {
        self.id = id
        self.name = name
        super.init()
    }
}

@objc(Event)
class EventObject: NSObject {
    
    @objc var id: Int
    @objc var name: String
    @objc var start: Date
    @objc var speakers: Set<PersonObject>
    
    init(id: Int, name: String, start: Date, speakers: Set<PersonObject>) {
        self.id = id
        self.name = name
        self.start = start
        self.speakers = speakers
        super.init()
    }
    
    enum CodingKeys: String, CodingKey, CaseIterable, Sendable {
        
        case id
        case name
        case start
        case speakers
    }
}

@objc(Attributes)
class AttributesObject: NSObject {
    
    @objc var string: String? = nil
    @objc var data: Data? = nil
    @objc var date: Date? = nil
    @objc var uuid: UUID? = nil
    @objc var bool: Bool = false
    @objc var int: Int = 0
    @objc var uint: UInt = 0
    @objc var uint8: UInt8 = 0
    @objc var uint16: UInt16 = 0
    @objc var uint32: UInt32 = 0
    @objc var uint64: UInt64 = 0
    @objc var int8: Int8 = 0
    @objc var int16: Int16 = 0
    @objc var int32: Int32 = 0
    @objc var int64: Int64 = 0
    @objc var float: Float = 0
    @objc var double: Double = 0
    @objc var numbers: [Int] = []
    @objc var strings: [String] = []
    
    override init() {
        super.init()
    }
}

#endif
