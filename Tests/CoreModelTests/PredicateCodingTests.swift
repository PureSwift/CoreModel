//
//  PredicateCodingTests.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/17/25.
//

import Foundation
import XCTest
@testable import CoreModel

final class PredicateCodingTests: XCTestCase {

    typealias Predicate = FetchRequest.Predicate

    enum Key: String, CodingKey {
        case name
        case age
    }

    func roundTrip(_ predicate: Predicate, file: StaticString = #filePath, line: UInt = #line) {
        do {
            let data = try JSONEncoder().encode(predicate)
            let decoded = try JSONDecoder().decode(Predicate.self, from: data)
            XCTAssertEqual(decoded, predicate, file: file, line: line)
        } catch {
            XCTFail("Failed to round trip: \(error)", file: file, line: line)
        }
    }

    func testPredicateType() {
        XCTAssertEqual(Predicate.value(true).type, .value)
        XCTAssertEqual(Predicate.comparison(.init(left: .attribute(.null), right: .attribute(.null))).type, .comparison)
        XCTAssertEqual(Predicate.compound(.and([])).type, .compound)
    }

    func testExpressionType() {
        XCTAssertEqual(Predicate.Expression.attribute(.null).type, .attribute)
        XCTAssertEqual(Predicate.Expression.relationship(.null).type, .relationship)
        XCTAssertEqual(Predicate.Expression.keyPath("name").type, .keyPath)
        XCTAssertEqual(Predicate.Expression.function(.init(name: "f", arguments: [])).type, .function)
    }

    func testCompoundAccessors() {
        let comparison = Predicate.comparison(.init(left: .keyPath("name"), right: .attribute(.string("x"))))
        XCTAssertEqual(Predicate.Compound.and([comparison]).type, .and)
        XCTAssertEqual(Predicate.Compound.or([comparison]).type, .or)
        XCTAssertEqual(Predicate.Compound.not(comparison).type, .not)
        XCTAssertEqual(Predicate.Compound.and([comparison, comparison]).subpredicates.count, 2)
        XCTAssertEqual(Predicate.Compound.or([comparison]).subpredicates.count, 1)
        XCTAssertEqual(Predicate.Compound.not(comparison).subpredicates, [comparison])
    }

    func testPredicateCodable() {
        let comparison = Predicate.comparison(
            .init(
                left: .keyPath("name"),
                right: .attribute(.string("John")),
                type: .beginsWith,
                modifier: .any,
                options: [.caseInsensitive, .diacriticInsensitive]
            )
        )
        roundTrip(comparison)
        roundTrip(.value(true))
        roundTrip(.value(false))
        roundTrip(.compound(.and([comparison, .value(true)])))
        roundTrip(.compound(.or([comparison, .value(false)])))
        roundTrip(.compound(.not(comparison)))
        // nested compounds
        roundTrip(.compound(.not(.compound(.and([comparison, .compound(.or([comparison]))])))))
    }

    func testExpressionCodable() throws {
        let expressions: [Predicate.Expression] = [
            .attribute(.string("test")),
            .attribute(.null),
            .relationship(.toOne("id1")),
            .relationship(.toMany(["id1", "id2"])),
            .keyPath("events.name"),
            .function(.init(name: "lowercase", arguments: [.keyPath("name"), .attribute(.int64(1))]))
        ]
        for expression in expressions {
            let data = try JSONEncoder().encode(expression)
            let decoded = try JSONDecoder().decode(Predicate.Expression.self, from: data)
            XCTAssertEqual(decoded, expression)
        }
    }

    func testDescriptions() {
        XCTAssertEqual(Predicate.value(true).description, "true")
        let comparison = Predicate.Comparison(
            left: .keyPath("name"),
            right: .attribute(.string("John")),
            type: .equalTo
        )
        XCTAssertEqual(comparison.description, #"name == "John""#)
        let modified = Predicate.Comparison(
            left: .keyPath("name"),
            right: .attribute(.string("j")),
            type: .beginsWith,
            modifier: .all,
            options: [.caseInsensitive, .diacriticInsensitive]
        )
        XCTAssertEqual(modified.description, #"ALL name BEGINSWITH[cd] "j""#)
        XCTAssertEqual(Predicate.comparison(comparison).description, comparison.description)
        // compound descriptions
        let and = Predicate.compound(.and([.comparison(comparison), .value(true)]))
        XCTAssertEqual(and.description, #"name == "John" AND true"#)
        let notNested = Predicate.compound(.not(and))
        XCTAssert(notNested.description.contains("NOT ("))
        XCTAssertEqual(Predicate.Compound.and([]).description, "(Empty and predicate)")
        // function expression description
        let function = Predicate.FunctionExpression(name: "f", arguments: [.keyPath("name"), .attribute(.int64(1))])
        XCTAssertEqual(function.description, "f(name, 1)")
        XCTAssertEqual(Predicate.Expression.function(function).description, "f(name, 1)")
    }

    func testAttributeValuePredicateDescriptions() {
        let date = Date(timeIntervalSince1970: 0)
        let uuid = UUID()
        let url = URL(string: "https://example.com")!
        XCTAssertEqual(Predicate.Expression.attribute(.null).description, "nil")
        XCTAssertEqual(Predicate.Expression.attribute(.string("x")).description, "\"x\"")
        XCTAssertEqual(Predicate.Expression.attribute(.bool(true)).description, "true")
        XCTAssertEqual(Predicate.Expression.attribute(.int16(1)).description, "1")
        XCTAssertEqual(Predicate.Expression.attribute(.int32(2)).description, "2")
        XCTAssertEqual(Predicate.Expression.attribute(.int64(3)).description, "3")
        XCTAssertEqual(Predicate.Expression.attribute(.float(1.5)).description, "1.5")
        XCTAssertEqual(Predicate.Expression.attribute(.double(2.5)).description, "2.5")
        XCTAssertEqual(Predicate.Expression.attribute(.date(date)).description, date.description)
        XCTAssertEqual(Predicate.Expression.attribute(.uuid(uuid)).description, uuid.uuidString)
        XCTAssertEqual(Predicate.Expression.attribute(.url(url)).description, url.description)
        XCTAssertEqual(Predicate.Expression.attribute(.data(Data([0x01]))).description, Data([0x01]).description)
        XCTAssertEqual(Predicate.Expression.attribute(.decimal(3)).description, "3")
        // relationship values
        XCTAssertEqual(Predicate.Expression.relationship(.null).description, "nil")
        XCTAssertEqual(Predicate.Expression.relationship(.toOne("a")).description, "a")
        XCTAssertEqual(Predicate.Expression.relationship(.toMany(["a", "b"])).description, "{a, b}")
    }

    func testComparisonOperators() {
        let name = Predicate.Expression.keyPath("name")
        let value = Predicate.Expression.attribute(.string("x"))
        func comparisonType(_ predicate: Predicate) -> Predicate.Comparison.Operator? {
            guard case let .comparison(comparison) = predicate else { return nil }
            return comparison.type
        }
        // expression op expression
        XCTAssertEqual(comparisonType(name < value), .lessThan)
        XCTAssertEqual(comparisonType(name <= value), .lessThanOrEqualTo)
        XCTAssertEqual(comparisonType(name > value), .greaterThan)
        XCTAssertEqual(comparisonType(name >= value), .greaterThanOrEqualTo)
        XCTAssertEqual(comparisonType(name == value), .equalTo)
        XCTAssertEqual(comparisonType(name != value), .notEqualTo)
        // string op value
        XCTAssertEqual(comparisonType("age" < 1), .lessThan)
        XCTAssertEqual(comparisonType("age" <= 1), .lessThanOrEqualTo)
        XCTAssertEqual(comparisonType("age" > 1), .greaterThan)
        XCTAssertEqual(comparisonType("age" >= 1), .greaterThanOrEqualTo)
        XCTAssertEqual(comparisonType("age" == 1), .equalTo)
        XCTAssertEqual(comparisonType("age" != 1), .notEqualTo)
        // coding key op value
        XCTAssertEqual(comparisonType(Key.age < 1), .lessThan)
        XCTAssertEqual(comparisonType(Key.age <= 1), .lessThanOrEqualTo)
        XCTAssertEqual(comparisonType(Key.age > 1), .greaterThan)
        XCTAssertEqual(comparisonType(Key.age >= 1), .greaterThanOrEqualTo)
        XCTAssertEqual(comparisonType(Key.age == 1), .equalTo)
        XCTAssertEqual(comparisonType(Key.age != 1), .notEqualTo)
    }

    func testCompareExtensions() {
        let rhs = Predicate.Expression.attribute(.string("x"))
        // string
        XCTAssertEqual("name".compare(.equalTo, rhs).type, .comparison)
        XCTAssertEqual("name".compare(.like, [.caseInsensitive], rhs).type, .comparison)
        XCTAssertEqual("name".compare(.any, .contains, [.diacriticInsensitive], rhs).type, .comparison)
        // coding key
        XCTAssertEqual(Key.name.compare(.equalTo, rhs).type, .comparison)
        XCTAssertEqual(Key.name.compare(.matches, [.normalized], rhs).type, .comparison)
        XCTAssertEqual(Key.name.compare(.all, .endsWith, [.localeSensitive], rhs).type, .comparison)
        // expression
        let lhs = Predicate.Expression.keyPath("name")
        XCTAssertEqual(lhs.compare(.in, rhs).type, .comparison)
        XCTAssertEqual(lhs.compare(.between, [.caseInsensitive], rhs).type, .comparison)
        XCTAssertEqual(lhs.compare(.any, .beginsWith, [.caseInsensitive], rhs).type, .comparison)
    }

    func testCompoundOperators() {
        let a = Predicate.value(true)
        let b = Predicate.value(false)
        XCTAssertEqual(a && b, .compound(.and([a, b])))
        XCTAssertEqual(a && [b, a], .compound(.and([a, b, a])))
        XCTAssertEqual(a || b, .compound(.or([a, b])))
        XCTAssertEqual(a || [b, a], .compound(.or([a, b, a])))
        XCTAssertEqual(!a, .compound(.not(a)))
    }

    func testKeyPath() {
        var keyPath: PredicateKeyPath = [.property("events"), .property("name")]
        XCTAssertEqual(keyPath.keys, [.property("events"), .property("name")])
        XCTAssertEqual(keyPath.rawValue, "events.name")
        XCTAssertEqual(keyPath.description, "events.name")
        // append / removal
        keyPath.append(.index(0))
        XCTAssertEqual(keyPath.rawValue, "events.name.0")
        XCTAssertEqual(keyPath.appending(.operator(.count)).rawValue, "events.name.0.@count")
        keyPath.append(contentsOf: [.property("id")])
        XCTAssertEqual(keyPath.appending(contentsOf: [PredicateKeyPath.Key.property("x")]).keys.count, 5)
        XCTAssertEqual(keyPath.removeFirst(), .property("events"))
        XCTAssertEqual(keyPath.removingFirst().keys.first, .index(0))
        XCTAssertEqual(keyPath.removeLast(), .property("id"))
        XCTAssertEqual(keyPath.removingLast().keys.count, keyPath.keys.count - 1)
        // begins(with:)
        let path: PredicateKeyPath = "events.name"
        XCTAssert(path.begins(with: "events"))
        XCTAssertFalse(path.begins(with: "people"))
        // raw value parsing
        let parsed = PredicateKeyPath(rawValue: "events.0.@count")
        XCTAssertEqual(parsed.keys, [.property("events"), .index(0), .operator(.count)])
        // operators
        for op in [PredicateKeyPath.Operator.count, .sum, .min, .max, .average] {
            XCTAssertEqual(PredicateKeyPath.Key(rawValue: op.rawValue), .operator(op))
            XCTAssertEqual(op.description, op.rawValue)
        }
        XCTAssertEqual(PredicateKeyPath.Key.index(1).description, "1")
        XCTAssertEqual(PredicateKeyPath.Key.property("a").description, "a")
    }

    func testStringComparisonHelpers() {
        let locale = Locale(identifier: "en_US")
        XCTAssert("apple".compare("APPLE", [.caseInsensitive], nil, .orderedSame))
        XCTAssertFalse("apple".compare("banana", [], nil, .orderedSame))
        XCTAssert("apple".compare("banana", [.localeSensitive], locale, .orderedAscending))
        XCTAssertNotNil("hello world".range(of: "WORLD", [.caseInsensitive], nil))
        XCTAssertNil("hello".range(of: "xyz", [], locale))
        XCTAssert("hello123".matches("[a-z]+[0-9]+", [], nil))
        XCTAssertFalse("hello".matches("^[0-9]+$", [.caseInsensitive], locale))
        XCTAssert("hello world".begins(with: "HELLO", [.caseInsensitive], nil))
        XCTAssertFalse("hello world".begins(with: "world", [], locale))
        XCTAssert("hello world".ends(with: "WORLD", [.caseInsensitive], nil))
        XCTAssertFalse("hello world".ends(with: "hello", [], locale))
        XCTAssert("héllo".compare("hello", [.diacriticInsensitive], nil, .orderedSame))
        XCTAssert("hello"[...].begins(with: "he"))
        XCTAssertFalse("hello"[...].begins(with: "lo"))
        // CompareOptions conversion
        XCTAssertEqual(String.CompareOptions(.caseInsensitive), .caseInsensitive)
        XCTAssertEqual(String.CompareOptions(.diacriticInsensitive), .diacriticInsensitive)
        XCTAssertNil(String.CompareOptions(.normalized))
        XCTAssertNil(String.CompareOptions(.localeSensitive))
    }

    func testCollectionHelpers() {
        XCTAssert([1, 2, 3].begins(with: [1, 2]))
        XCTAssertFalse([1, 2, 3].begins(with: [2]))
        // contains(_:) is a *contiguous subsequence* search — the string
        // `.contains` predicate resolves to it on platforms without
        // Foundation's `StringProtocol.contains` (Embedded Swift), so
        // every-element membership is not enough: searching locations for
        // "mill" must not match "1150 Timber Lane" just because all of
        // m/i/l/l appear somewhere in it.
        XCTAssert([1, 2, 3].contains([2, 3]))
        XCTAssert([1, 2, 3].contains([1, 2, 3]))
        XCTAssertFalse([1, 2, 3].contains([3, 1]))
        XCTAssertFalse([1, 2].contains([1, 4]))
        XCTAssert(Array("millbrook").contains(Array("mill")))
        XCTAssertFalse(Array("1150 timber lane").contains(Array("mill")))
    }
}
