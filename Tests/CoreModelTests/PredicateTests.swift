//
//  PredicateTests.swift
//  
//
//  Created by Alsey Coleman Miller on 4/12/20.
//

import Foundation
import XCTest
@testable import CoreModel

final class PredicateTests: XCTestCase {
    
    func testDescription() {
        
        XCTAssertEqual((.keyPath("name") == .attribute(.string("Coleman"))).description, "name == \"Coleman\"")
        XCTAssertEqual(((.keyPath("name") != .attribute(.null)) as FetchRequest.Predicate).description, "name != nil")
        XCTAssertEqual((!(.keyPath("name") == .attribute(.null))).description, "NOT name == nil")
        XCTAssertEqual(("isValid" == false).description, "isValid == false")
    }
    
    func testPredicate1() {
        
        let predicate: FetchRequest.Predicate = "id" > Int64(0)
            && "id" != Int64(99)
            && "name".compare(.beginsWith, .attribute(.string("C")))
            && "name".compare(.contains, [.diacriticInsensitive, .caseInsensitive], .attribute(.string("COLE")))
        
        XCTAssertEqual(predicate.description, #"((id > 0 AND id != 99) AND name BEGINSWITH "C") AND name CONTAINS[cd] "COLE""#)
    }
    
    func testPredicate2() {
        
        let events = [
            Event(
                id: 1,
                name: "Event 1",
                start: Date(timeIntervalSince1970: 0),
                speakers: [
                    Person(
                        id: 1,
                        name: "Alsey Coleman Miller"
                    )
            ]),
            Event(
                id: 2,
                name: "Event 2",
                start: Date(timeIntervalSince1970: 60 * 60 * 2),
                speakers: [
                    Person(
                        id: 2,
                        name: "John Apple"
                    )
            ]),
            Event(
                id: 3,
                name: "Event 3",
                start: Date(timeIntervalSince1970: 60 * 60 * 4),
                speakers: [
                    Person(
                        id: 1,
                        name: "Alsey Coleman Miller"
                    ),
                    Person(
                        id: 2,
                        name: "John Apple"
                    )
            ])
        ]
        
        let future = Date.distantFuture
        
        let predicate: FetchRequest.Predicate = ("name").compare(.matches, [.caseInsensitive], .attribute(.string(#"event \d"#))) && [
            ("start") < future,
            ("speakers.@count") > 0
            ]
        
        #if !os(WASI)
        XCTAssertEqual(predicate.description, #"name MATCHES[c] "event \d" AND start < 4001-01-01 00:00:00 +0000 AND speakers.@count > 0"#)
        #endif
    }
}

// MARK: - Supporting Types

internal extension PredicateTests {
    
    struct ID: RawRepresentable, Equatable, Hashable, Codable {
        
        public let rawValue: UInt
        
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
    }
    
    struct Person: Equatable, Hashable, Codable {
        
        var id: ID
        var name: String
        
        init(id: ID, name: String) {
            self.id = id
            self.name = name
        }
    }

    struct Event: Equatable, Hashable, Codable {
        
        var id: ID
        var name: String
        var start: Date
        var speakers: [Person]
        
        init(id: ID, name: String, start: Date, speakers: [Person]) {
            self.id = id
            self.name = name
            self.start = start
            self.speakers = speakers
        }
    }
}

extension PredicateTests.ID: ExpressibleByIntegerLiteral {
    
    public init(integerLiteral value: UInt) {
        self.init(rawValue: value)
    }
}
