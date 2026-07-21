//
//  PredicateEvaluationTests.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/21/26.
//

import Foundation
import XCTest
@testable import CoreModel

final class PredicateEvaluationTests: XCTestCase {

    private let person = ModelData(
        entity: "Person",
        id: "1",
        attributes: [
            "name": .string("Alice"),
            "age": .int16(30),
            "score": .double(4.5),
            "verified": .bool(true),
            "nickname": .null
        ],
        relationships: [
            "boss": .toOne("100"),
            "events": .toMany(["10", "20"])
        ]
    )

    func testValue() {
        XCTAssert(FetchRequest.Predicate.value(true).evaluate(with: person))
        XCTAssertFalse(FetchRequest.Predicate.value(false).evaluate(with: person))
    }

    func testEquality() {
        XCTAssert(("name" == "Alice").evaluate(with: person))
        XCTAssertFalse(("name" == "Bob").evaluate(with: person))
        XCTAssert(("name" != "Bob").evaluate(with: person))
        XCTAssert(("age" == 30).evaluate(with: person))
        XCTAssert(("verified" == true).evaluate(with: person))
        // numeric comparison across integer types
        XCTAssert(("age" == Int64(30)).evaluate(with: person))
    }

    func testCaseInsensitiveEquality() {
        let predicate = "name".compare(.equalTo, [.caseInsensitive], .attribute(.string("ALICE")))
        XCTAssert(predicate.evaluate(with: person))
        XCTAssertFalse(("name" == "ALICE").evaluate(with: person))
    }

    func testNull() {
        // a null attribute equals a nil / missing value
        XCTAssert("nickname".compare(.equalTo, .attribute(.null)).evaluate(with: person))
        XCTAssert("missingKey".compare(.equalTo, .attribute(.null)).evaluate(with: person))
        XCTAssertFalse("name".compare(.equalTo, .attribute(.null)).evaluate(with: person))
    }

    func testOrdering() {
        XCTAssert(("age" > 21).evaluate(with: person))
        XCTAssert(("age" >= 30).evaluate(with: person))
        XCTAssert(("age" < 31).evaluate(with: person))
        XCTAssert(("age" <= 30).evaluate(with: person))
        XCTAssertFalse(("age" > 30).evaluate(with: person))
        XCTAssert(("score" > 4.0).evaluate(with: person))
        // string ordering
        XCTAssert(("name" < "Bob").evaluate(with: person))
        // values that aren't order-comparable
        XCTAssertFalse(("verified" > "Alice").evaluate(with: person))
    }

    func testStringOperators() {
        XCTAssert("name".compare(.beginsWith, .attribute(.string("Al"))).evaluate(with: person))
        XCTAssert("name".compare(.endsWith, .attribute(.string("ice"))).evaluate(with: person))
        XCTAssert("name".compare(.contains, .attribute(.string("lic"))).evaluate(with: person))
        XCTAssertFalse("name".compare(.beginsWith, .attribute(.string("Bo"))).evaluate(with: person))
        XCTAssert("name".compare(.beginsWith, [.caseInsensitive], .attribute(.string("al"))).evaluate(with: person))
        // IN: left hand side is a substring of the right hand side
        XCTAssert("name".compare(.in, .attribute(.string("Alice in Wonderland"))).evaluate(with: person))
    }

    func testLike() {
        XCTAssert("name".compare(.like, .attribute(.string("A*"))).evaluate(with: person))
        XCTAssert("name".compare(.like, .attribute(.string("?lice"))).evaluate(with: person))
        XCTAssert("name".compare(.like, .attribute(.string("*ice"))).evaluate(with: person))
        XCTAssert("name".compare(.like, .attribute(.string("A*e"))).evaluate(with: person))
        XCTAssertFalse("name".compare(.like, .attribute(.string("B*"))).evaluate(with: person))
        XCTAssertFalse("name".compare(.like, .attribute(.string("Alic?e"))).evaluate(with: person))
        XCTAssert("name".compare(.like, [.caseInsensitive], .attribute(.string("a*"))).evaluate(with: person))
    }

    func testMatches() {
        XCTAssert("name".compare(.matches, .attribute(.string("A[a-z]+e"))).evaluate(with: person))
        XCTAssertFalse("name".compare(.matches, .attribute(.string("^B.*"))).evaluate(with: person))
    }

    func testRelationships() {
        // to-one equality against an identifier
        XCTAssert("boss".compare(.equalTo, .relationship(.toOne("100"))).evaluate(with: person))
        XCTAssert("boss".compare(.equalTo, .attribute(.string("100"))).evaluate(with: person))
        XCTAssertFalse("boss".compare(.equalTo, .relationship(.toOne("999"))).evaluate(with: person))
        // to-many contains an identifier
        XCTAssert("events".compare(.contains, .relationship(.toOne("10"))).evaluate(with: person))
        XCTAssert("events".compare(.contains, .attribute(.string("20"))).evaluate(with: person))
        XCTAssertFalse("events".compare(.contains, .attribute(.string("30"))).evaluate(with: person))
        // identifier is in a to-many relationship
        let predicate = FetchRequest.Predicate.comparison(
            .init(left: .attribute(.string("10")), right: .keyPath("events"), type: .in)
        )
        XCTAssert(predicate.evaluate(with: person))
    }

    func testModifiers() {
        let anyMatch = "events".compare(.any, .equalTo, [], .attribute(.string("10")))
        XCTAssert(anyMatch.evaluate(with: person))
        let anyMiss = "events".compare(.any, .equalTo, [], .attribute(.string("30")))
        XCTAssertFalse(anyMiss.evaluate(with: person))
        let allMatch = "events".compare(.all, .in, [], .relationship(.toMany(["10", "20", "30"])))
        XCTAssert(allMatch.evaluate(with: person))
        let allMiss = "events".compare(.all, .equalTo, [], .attribute(.string("10")))
        XCTAssertFalse(allMiss.evaluate(with: person))
    }

    func testCompound() {
        let isAlice: FetchRequest.Predicate = "name" == "Alice"
        let isAdult: FetchRequest.Predicate = "age" >= 18
        let isBob: FetchRequest.Predicate = "name" == "Bob"
        XCTAssert((isAlice && isAdult).evaluate(with: person))
        XCTAssertFalse((isAlice && isBob).evaluate(with: person))
        XCTAssert((isBob || isAdult).evaluate(with: person))
        XCTAssert((!isBob).evaluate(with: person))
        XCTAssertFalse((!isAlice).evaluate(with: person))
    }

    func testFunctionExpression() {
        let uppercase = DatabaseFunction(name: "UPPERCASE", argumentCount: 1) { arguments in
            guard case let .string(value)? = arguments.first ?? nil else { return nil }
            return .string(value.uppercased())
        }
        let predicate = FetchRequest.Predicate.comparison(
            .init(
                left: .function(.init(name: "UPPERCASE", arguments: [.keyPath("name")])),
                right: .attribute(.string("ALICE"))
            )
        )
        XCTAssert(predicate.evaluate(with: person, functions: ["UPPERCASE": uppercase]))
        // unregistered functions evaluate to nil, which doesn't equal a string
        XCTAssertFalse(predicate.evaluate(with: person))
    }

    func testWildcardMatch() {
        XCTAssert(String.wildcardMatch("", pattern: ""))
        XCTAssert(String.wildcardMatch("", pattern: "*"))
        XCTAssertFalse(String.wildcardMatch("", pattern: "?"))
        XCTAssert(String.wildcardMatch("abc", pattern: "*"))
        XCTAssert(String.wildcardMatch("abc", pattern: "a*c"))
        XCTAssert(String.wildcardMatch("abbbc", pattern: "a*c"))
        XCTAssert(String.wildcardMatch("abc", pattern: "a**c"))
        XCTAssertFalse(String.wildcardMatch("abd", pattern: "a*c"))
        XCTAssert(String.wildcardMatch("abc", pattern: "???"))
        XCTAssertFalse(String.wildcardMatch("abc", pattern: "??"))
    }

    func testFetchRequestEvaluation() {
        let people: [ModelData] = (1...5).map { index in
            ModelData(
                entity: "Person",
                id: ObjectID(rawValue: "\(index)"),
                attributes: [
                    "name": .string("Person \(index)"),
                    "age": .int16(Int16(20 + index))
                ]
            )
        }
        let other = ModelData(entity: "Event", id: "99")
        let all = people + [other]
        // filters by entity
        XCTAssertEqual(FetchRequest(entity: "Person").evaluate(all).count, 5)
        // predicate
        let adults = FetchRequest(entity: "Person", predicate: "age" > 22).evaluate(all)
        XCTAssertEqual(adults.map { $0.id }, ["3", "4", "5"])
        // sort descending
        let sorted = FetchRequest(
            entity: "Person",
            sortDescriptors: [.init(property: "age", ascending: false)]
        ).evaluate(all)
        XCTAssertEqual(sorted.map { $0.id }, ["5", "4", "3", "2", "1"])
        // limit and offset
        let page = FetchRequest(
            entity: "Person",
            sortDescriptors: [.init(property: "age", ascending: true)],
            fetchLimit: 2,
            fetchOffset: 1
        ).evaluate(all)
        XCTAssertEqual(page.map { $0.id }, ["2", "3"])
        // offset past the end
        let empty = FetchRequest(entity: "Person", fetchOffset: 10).evaluate(all)
        XCTAssertEqual(empty, [])
    }

    func testSorting() {
        let people: [ModelData] = [
            ModelData(entity: "Person", id: "b", attributes: ["age": .int16(30), "name": .string("Bob")]),
            ModelData(entity: "Person", id: "a", attributes: ["age": .int16(30), "name": .string("Alice")]),
            ModelData(entity: "Person", id: "c", attributes: ["age": .int16(25), "name": .string("Charlie")])
        ]
        // empty descriptors sort by identifier
        XCTAssertEqual(people.sorted(by: []).map { $0.id }, ["a", "b", "c"])
        // ties broken by identifier
        let byAge = people.sorted(by: [.init(property: "age", ascending: true)])
        XCTAssertEqual(byAge.map { $0.id }, ["c", "a", "b"])
        // multiple descriptors
        let byAgeThenName = people.sorted(by: [
            .init(property: "age", ascending: false),
            .init(property: "name", ascending: false)
        ])
        XCTAssertEqual(byAgeThenName.map { $0.id }, ["b", "a", "c"])
        // function sort term
        let negate = DatabaseFunction(name: "NEGATE", argumentCount: 1) { arguments in
            guard case let .int16(value)? = arguments.first ?? nil else { return nil }
            return .int16(-value)
        }
        let byNegatedAge = people.sorted(
            by: [.init(term: .function(.init(name: "NEGATE", arguments: [.keyPath("age")])), ascending: true)],
            functions: ["NEGATE": negate]
        )
        XCTAssertEqual(byNegatedAge.map { $0.id }, ["a", "b", "c"])
    }

    func testFiltering() {
        let people: [ModelData] = [
            ModelData(entity: "Person", id: "a", attributes: ["name": .string("Alice")]),
            ModelData(entity: "Person", id: "b", attributes: ["name": .string("Bob")])
        ]
        XCTAssertEqual(people.filtered(by: "name" == "Bob").map { $0.id }, ["b"])
        XCTAssertEqual(people.filtered(by: .value(false)), [])
    }
}
