//
//  PredicateCodingTests.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/17/25.
//

import Foundation
import Testing
@testable import CoreModel

@Suite struct PredicateCodingTests {

    typealias Predicate = FetchRequest.Predicate

    enum Key: String, CodingKey {
        case name
        case age
    }

    func roundTrip(_ predicate: Predicate, sourceLocation: SourceLocation = #_sourceLocation) {
        do {
            let data = try JSONEncoder().encode(predicate)
            let decoded = try JSONDecoder().decode(Predicate.self, from: data)
            #expect(decoded == predicate, sourceLocation: sourceLocation)
        } catch {
            Issue.record("Failed to round trip: \(error)", sourceLocation: sourceLocation)
        }
    }

    @Test func predicateType() {
        #expect(Predicate.value(true).type == .value)
        #expect(Predicate.comparison(.init(left: .attribute(.null), right: .attribute(.null))).type == .comparison)
        #expect(Predicate.compound(.and([])).type == .compound)
    }

    @Test func expressionType() {
        #expect(Predicate.Expression.attribute(.null).type == .attribute)
        #expect(Predicate.Expression.relationship(.null).type == .relationship)
        #expect(Predicate.Expression.keyPath("name").type == .keyPath)
        #expect(Predicate.Expression.function(.init(name: "f", arguments: [])).type == .function)
    }

    @Test func compoundAccessors() {
        let comparison = Predicate.comparison(.init(left: .keyPath("name"), right: .attribute(.string("x"))))
        #expect(Predicate.Compound.and([comparison]).type == .and)
        #expect(Predicate.Compound.or([comparison]).type == .or)
        #expect(Predicate.Compound.not(comparison).type == .not)
        #expect(Predicate.Compound.and([comparison, comparison]).subpredicates.count == 2)
        #expect(Predicate.Compound.or([comparison]).subpredicates.count == 1)
        #expect(Predicate.Compound.not(comparison).subpredicates == [comparison])
    }

    @Test func predicateCodable() {
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

    @Test func expressionCodable() throws {
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
            #expect(decoded == expression)
        }
    }

    @Test func descriptions() {
        #expect(Predicate.value(true).description == "true")
        let comparison = Predicate.Comparison(
            left: .keyPath("name"),
            right: .attribute(.string("John")),
            type: .equalTo
        )
        #expect(comparison.description == #"name == "John""#)
        let modified = Predicate.Comparison(
            left: .keyPath("name"),
            right: .attribute(.string("j")),
            type: .beginsWith,
            modifier: .all,
            options: [.caseInsensitive, .diacriticInsensitive]
        )
        #expect(modified.description == #"ALL name BEGINSWITH[cd] "j""#)
        #expect(Predicate.comparison(comparison).description == comparison.description)
        // compound descriptions
        let and = Predicate.compound(.and([.comparison(comparison), .value(true)]))
        #expect(and.description == #"name == "John" AND true"#)
        let notNested = Predicate.compound(.not(and))
        #expect(notNested.description.contains("NOT ("))
        #expect(Predicate.Compound.and([]).description == "(Empty and predicate)")
        // function expression description
        let function = Predicate.FunctionExpression(name: "f", arguments: [.keyPath("name"), .attribute(.int64(1))])
        #expect(function.description == "f(name, 1)")
        #expect(Predicate.Expression.function(function).description == "f(name, 1)")
    }

    @Test func attributeValuePredicateDescriptions() {
        let date = Date(timeIntervalSince1970: 0)
        let uuid = UUID()
        let url = URL(string: "https://example.com")!
        #expect(Predicate.Expression.attribute(.null).description == "nil")
        #expect(Predicate.Expression.attribute(.string("x")).description == "\"x\"")
        #expect(Predicate.Expression.attribute(.bool(true)).description == "true")
        #expect(Predicate.Expression.attribute(.int16(1)).description == "1")
        #expect(Predicate.Expression.attribute(.int32(2)).description == "2")
        #expect(Predicate.Expression.attribute(.int64(3)).description == "3")
        #expect(Predicate.Expression.attribute(.float(1.5)).description == "1.5")
        #expect(Predicate.Expression.attribute(.double(2.5)).description == "2.5")
        #expect(Predicate.Expression.attribute(.date(date)).description == date.description)
        #expect(Predicate.Expression.attribute(.uuid(uuid)).description == uuid.uuidString)
        #expect(Predicate.Expression.attribute(.url(url)).description == url.description)
        #expect(Predicate.Expression.attribute(.data(Data([0x01]))).description == Data([0x01]).description)
        #expect(Predicate.Expression.attribute(.decimal(3)).description == "3")
        // relationship values
        #expect(Predicate.Expression.relationship(.null).description == "nil")
        #expect(Predicate.Expression.relationship(.toOne("a")).description == "a")
        #expect(Predicate.Expression.relationship(.toMany(["a", "b"])).description == "{a, b}")
    }

    @Test func comparisonOperators() {
        let name = Predicate.Expression.keyPath("name")
        let value = Predicate.Expression.attribute(.string("x"))
        func comparisonType(_ predicate: Predicate) -> Predicate.Comparison.Operator? {
            guard case let .comparison(comparison) = predicate else { return nil }
            return comparison.type
        }
        // expression op expression
        #expect(comparisonType(name < value) == .lessThan)
        #expect(comparisonType(name <= value) == .lessThanOrEqualTo)
        #expect(comparisonType(name > value) == .greaterThan)
        #expect(comparisonType(name >= value) == .greaterThanOrEqualTo)
        #expect(comparisonType(name == value) == .equalTo)
        #expect(comparisonType(name != value) == .notEqualTo)
        // string op value
        #expect(comparisonType("age" < 1) == .lessThan)
        #expect(comparisonType("age" <= 1) == .lessThanOrEqualTo)
        #expect(comparisonType("age" > 1) == .greaterThan)
        #expect(comparisonType("age" >= 1) == .greaterThanOrEqualTo)
        #expect(comparisonType("age" == 1) == .equalTo)
        #expect(comparisonType("age" != 1) == .notEqualTo)
        // coding key op value
        #expect(comparisonType(Key.age < 1) == .lessThan)
        #expect(comparisonType(Key.age <= 1) == .lessThanOrEqualTo)
        #expect(comparisonType(Key.age > 1) == .greaterThan)
        #expect(comparisonType(Key.age >= 1) == .greaterThanOrEqualTo)
        #expect(comparisonType(Key.age == 1) == .equalTo)
        #expect(comparisonType(Key.age != 1) == .notEqualTo)
    }

    @Test func compareExtensions() {
        let rhs = Predicate.Expression.attribute(.string("x"))
        // string
        #expect("name".compare(.equalTo, rhs).type == .comparison)
        #expect("name".compare(.like, [.caseInsensitive], rhs).type == .comparison)
        #expect("name".compare(.any, .contains, [.diacriticInsensitive], rhs).type == .comparison)
        // coding key
        #expect(Key.name.compare(.equalTo, rhs).type == .comparison)
        #expect(Key.name.compare(.matches, [.normalized], rhs).type == .comparison)
        #expect(Key.name.compare(.all, .endsWith, [.localeSensitive], rhs).type == .comparison)
        // expression
        let lhs = Predicate.Expression.keyPath("name")
        #expect(lhs.compare(.in, rhs).type == .comparison)
        #expect(lhs.compare(.between, [.caseInsensitive], rhs).type == .comparison)
        #expect(lhs.compare(.any, .beginsWith, [.caseInsensitive], rhs).type == .comparison)
    }

    @Test func compoundOperators() {
        let a = Predicate.value(true)
        let b = Predicate.value(false)
        #expect((a && b) == .compound(.and([a, b])))
        #expect((a && [b, a]) == .compound(.and([a, b, a])))
        #expect((a || b) == .compound(.or([a, b])))
        #expect((a || [b, a]) == .compound(.or([a, b, a])))
        #expect((!a) == .compound(.not(a)))
    }

    @Test func keyPath() {
        var keyPath: PredicateKeyPath = [.property("events"), .property("name")]
        #expect(keyPath.keys == [.property("events"), .property("name")])
        #expect(keyPath.rawValue == "events.name")
        #expect(keyPath.description == "events.name")
        // append / removal
        keyPath.append(.index(0))
        #expect(keyPath.rawValue == "events.name.0")
        #expect(keyPath.appending(.operator(.count)).rawValue == "events.name.0.@count")
        keyPath.append(contentsOf: [.property("id")])
        #expect(keyPath.appending(contentsOf: [PredicateKeyPath.Key.property("x")]).keys.count == 5)
        #expect(keyPath.removeFirst() == .property("events"))
        #expect(keyPath.removingFirst().keys.first == .index(0))
        #expect(keyPath.removeLast() == .property("id"))
        #expect(keyPath.removingLast().keys.count == keyPath.keys.count - 1)
        // begins(with:)
        let path: PredicateKeyPath = "events.name"
        #expect(path.begins(with: "events"))
        #expect(path.begins(with: "people") == false)
        // raw value parsing
        let parsed = PredicateKeyPath(rawValue: "events.0.@count")
        #expect(parsed.keys == [.property("events"), .index(0), .operator(.count)])
        // operators
        for op in [PredicateKeyPath.Operator.count, .sum, .min, .max, .average] {
            #expect(PredicateKeyPath.Key(rawValue: op.rawValue) == .operator(op))
            #expect(op.description == op.rawValue)
        }
        #expect(PredicateKeyPath.Key.index(1).description == "1")
        #expect(PredicateKeyPath.Key.property("a").description == "a")
    }

    @Test func stringComparisonHelpers() {
        let locale = Locale(identifier: "en_US")
        let caseInsensitive: Set<Predicate.Comparison.Option> = [.caseInsensitive]
        let localeSensitive: Set<Predicate.Comparison.Option> = [.localeSensitive]
        let diacriticInsensitive: Set<Predicate.Comparison.Option> = [.diacriticInsensitive]
        let noOptions: Set<Predicate.Comparison.Option> = []
        #expect("apple".compare("APPLE", caseInsensitive, nil, .orderedSame))
        #expect("apple".compare("banana", noOptions, nil, .orderedSame) == false)
        #expect("apple".compare("banana", localeSensitive, locale, .orderedAscending))
        #expect("hello world".range(of: "WORLD", caseInsensitive, nil) != nil)
        #expect("hello".range(of: "xyz", noOptions, locale) == nil)
        #expect("hello123".matches("[a-z]+[0-9]+", noOptions, nil))
        #expect("hello".matches("^[0-9]+$", caseInsensitive, locale) == false)
        #expect("hello world".begins(with: "HELLO", caseInsensitive, nil))
        #expect("hello world".begins(with: "world", noOptions, locale) == false)
        #expect("hello world".ends(with: "WORLD", caseInsensitive, nil))
        #expect("hello world".ends(with: "hello", noOptions, locale) == false)
        #expect("héllo".compare("hello", diacriticInsensitive, nil, .orderedSame))
        #expect("hello"[...].begins(with: "he"))
        #expect("hello"[...].begins(with: "lo") == false)
        // CompareOptions conversion
        #expect(String.CompareOptions(.caseInsensitive) == .caseInsensitive)
        #expect(String.CompareOptions(.diacriticInsensitive) == .diacriticInsensitive)
        #expect(String.CompareOptions(.normalized) == nil)
        #expect(String.CompareOptions(.localeSensitive) == nil)
    }

    @Test func collectionHelpers() {
        #expect([1, 2, 3].begins(with: [1, 2]))
        #expect([1, 2, 3].begins(with: [2]) == false)
        // contains(_:) is a *contiguous subsequence* search — the string
        // `.contains` predicate resolves to it on platforms without
        // Foundation's `StringProtocol.contains` (Embedded Swift), so
        // every-element membership is not enough: searching locations for
        // "mill" must not match "1150 Timber Lane" just because all of
        // m/i/l/l appear somewhere in it.
        #expect([1, 2, 3].contains([2, 3]))
        #expect([1, 2, 3].contains([1, 2, 3]))
        #expect([1, 2, 3].contains([3, 1]) == false)
        #expect([1, 2].contains([1, 4]) == false)
        #expect(Array("millbrook").contains(Array("mill")))
        #expect(Array("1150 timber lane").contains(Array("mill")) == false)
    }
}
