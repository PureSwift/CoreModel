//
//  FoundationPredicateTests.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 8/16/26.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif
import Testing
@testable import CoreModel

@Suite struct FoundationPredicateTests {

    struct PersonModel {

        var name: String
        var age: Int
        var isActive: Bool
        var nickname: String?
        var height: Double
        var friends: [FriendModel]
        var scores: [Int]
    }

    struct FriendModel {

        var name: String
        var age: Int
    }

    static var people: [ModelData] {
        [
            ("Alice", 30, true),
            ("Bob", 17, false),
            ("Alina", 20, true)
        ].map { name, age, isActive in
            ModelData(
                entity: "Person",
                id: ObjectID(rawValue: name),
                attributes: [
                    "name": .string(name),
                    "age": .int64(numericCast(age)),
                    "isActive": .bool(isActive)
                ]
            )
        }
    }

    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    @Test func comparison() throws {

        let predicate = try FetchRequest.Predicate(#Predicate<PersonModel> { $0.name == "Alice" })
        #expect(predicate == .comparison(.init(left: .keyPath("name"), right: .attribute(.string("Alice")), type: .equalTo)))
        #expect(Self.people.filtered(by: predicate).map(\.id.rawValue) == ["Alice"])

        let notEqual = try FetchRequest.Predicate(#Predicate<PersonModel> { $0.name != "Alice" })
        #expect(notEqual == .comparison(.init(left: .keyPath("name"), right: .attribute(.string("Alice")), type: .notEqualTo)))

        let lessThan = try FetchRequest.Predicate(#Predicate<PersonModel> { $0.age < 18 })
        #expect(lessThan == .comparison(.init(left: .keyPath("age"), right: .attribute(.int64(18)), type: .lessThan)))
        #expect(Self.people.filtered(by: lessThan).map(\.id.rawValue) == ["Bob"])

        let greaterThanOrEqual = try FetchRequest.Predicate(#Predicate<PersonModel> { $0.age >= 20 })
        #expect(greaterThanOrEqual == .comparison(.init(left: .keyPath("age"), right: .attribute(.int64(20)), type: .greaterThanOrEqualTo)))
        #expect(Self.people.filtered(by: greaterThanOrEqual).map(\.id.rawValue) == ["Alice", "Alina"])
    }

    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    @Test func compound() throws {

        // nested conjunctions are flattened into a single AND
        let and = try FetchRequest.Predicate(#Predicate<PersonModel> { $0.age >= 18 && $0.isActive && $0.name != "Bob" })
        #expect(and == .compound(.and([
            .comparison(.init(left: .keyPath("age"), right: .attribute(.int64(18)), type: .greaterThanOrEqualTo)),
            .comparison(.init(left: .keyPath("isActive"), right: .attribute(.bool(true)), type: .equalTo)),
            .comparison(.init(left: .keyPath("name"), right: .attribute(.string("Bob")), type: .notEqualTo))
        ])))
        #expect(Self.people.filtered(by: and).map(\.id.rawValue) == ["Alice", "Alina"])

        let or = try FetchRequest.Predicate(#Predicate<PersonModel> { $0.name == "Bob" || $0.age > 25 })
        #expect(or == .compound(.or([
            .comparison(.init(left: .keyPath("name"), right: .attribute(.string("Bob")), type: .equalTo)),
            .comparison(.init(left: .keyPath("age"), right: .attribute(.int64(25)), type: .greaterThan))
        ])))
        #expect(Self.people.filtered(by: or).map(\.id.rawValue) == ["Alice", "Bob"])

        let not = try FetchRequest.Predicate(#Predicate<PersonModel> { !$0.isActive })
        #expect(not == .compound(.not(.comparison(.init(left: .keyPath("isActive"), right: .attribute(.bool(true)), type: .equalTo)))))
        #expect(Self.people.filtered(by: not).map(\.id.rawValue) == ["Bob"])
    }

    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    @Test func string() throws {

        let contains = try FetchRequest.Predicate(#Predicate<PersonModel> { $0.name.contains("li") })
        #expect(contains == .comparison(.init(left: .keyPath("name"), right: .attribute(.string("li")), type: .contains)))
        #expect(Self.people.filtered(by: contains).map(\.id.rawValue) == ["Alice", "Alina"])

        let starts = try FetchRequest.Predicate(#Predicate<PersonModel> { $0.name.starts(with: "Al") })
        #expect(starts == .comparison(.init(left: .keyPath("name"), right: .attribute(.string("Al")), type: .beginsWith)))
        #expect(Self.people.filtered(by: starts).map(\.id.rawValue) == ["Alice", "Alina"])
    }

    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    @Test func range() throws {

        // ranges lower to a compound comparison since BETWEEN isn't evaluatable
        let range = try FetchRequest.Predicate(#Predicate<PersonModel> { (18...25).contains($0.age) })
        #expect(range == .compound(.and([
            .comparison(.init(left: .keyPath("age"), right: .attribute(.int64(18)), type: .greaterThanOrEqualTo)),
            .comparison(.init(left: .keyPath("age"), right: .attribute(.int64(25)), type: .lessThanOrEqualTo))
        ])))
        #expect(Self.people.filtered(by: range).map(\.id.rawValue) == ["Alina"])
    }

    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    @Test func booleanProperty() throws {

        // a boolean property used directly becomes an equality comparison
        let predicate = try FetchRequest.Predicate(#Predicate<PersonModel> { $0.isActive })
        #expect(predicate == .comparison(.init(left: .keyPath("isActive"), right: .attribute(.bool(true)), type: .equalTo)))
        #expect(Self.people.filtered(by: predicate).map(\.id.rawValue) == ["Alice", "Alina"])
    }

    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    @Test func constant() throws {

        let predicate = try FetchRequest.Predicate(#Predicate<PersonModel> { _ in true })
        #expect(predicate == .value(true))
        #expect(Self.people.filtered(by: predicate).count == 3)
    }

    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    @Test func optionalValue() throws {

        let predicate = try FetchRequest.Predicate(#Predicate<PersonModel> { $0.nickname == nil })
        #expect(predicate == .comparison(.init(left: .keyPath("nickname"), right: .attribute(.null), type: .equalTo)))
    }

    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    @Test func arithmetic() throws {

        let add = try FetchRequest.Predicate(#Predicate<PersonModel> { $0.age + 1 > 18 })
        #expect(add == .comparison(.init(
            left: .arithmetic(.init(function: .add, left: .keyPath("age"), right: .attribute(.int64(1)))),
            right: .attribute(.int64(18)),
            type: .greaterThan
        )))
        #expect(Self.people.filtered(by: add).map(\.id.rawValue) == ["Alice", "Alina"])

        let subtract = try FetchRequest.Predicate(#Predicate<PersonModel> { $0.age - 10 >= 18 })
        #expect(subtract == .comparison(.init(
            left: .arithmetic(.init(function: .subtract, left: .keyPath("age"), right: .attribute(.int64(10)))),
            right: .attribute(.int64(18)),
            type: .greaterThanOrEqualTo
        )))
        #expect(Self.people.filtered(by: subtract).map(\.id.rawValue) == ["Alice"])

        let multiply = try FetchRequest.Predicate(#Predicate<PersonModel> { $0.age * 2 == 40 })
        #expect(multiply == .comparison(.init(
            left: .arithmetic(.init(function: .multiply, left: .keyPath("age"), right: .attribute(.int64(2)))),
            right: .attribute(.int64(40)),
            type: .equalTo
        )))
        #expect(Self.people.filtered(by: multiply).map(\.id.rawValue) == ["Alina"])

        let divide = try FetchRequest.Predicate(#Predicate<PersonModel> { $0.height / 2 < 1.0 })
        #expect(divide == .comparison(.init(
            left: .arithmetic(.init(function: .divide, left: .keyPath("height"), right: .attribute(.double(2)))),
            right: .attribute(.double(1.0)),
            type: .lessThan
        )))

        let modulus = try FetchRequest.Predicate(#Predicate<PersonModel> { $0.age % 2 == 0 })
        #expect(modulus == .comparison(.init(
            left: .arithmetic(.init(function: .modulus, left: .keyPath("age"), right: .attribute(.int64(2)))),
            right: .attribute(.int64(0)),
            type: .equalTo
        )))
        #expect(Self.people.filtered(by: modulus).map(\.id.rawValue) == ["Alice", "Alina"])

        // unary minus lowers to multiplication by -1
        let negated = try FetchRequest.Predicate(#Predicate<PersonModel> { -$0.age < 0 })
        #expect(negated == .comparison(.init(
            left: .arithmetic(.init(function: .multiply, left: .keyPath("age"), right: .attribute(.int64(-1)))),
            right: .attribute(.int64(0)),
            type: .lessThan
        )))
        #expect(Self.people.filtered(by: negated).count == 3)
    }

    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    @Test func halfOpenRange() throws {

        let range = try FetchRequest.Predicate(#Predicate<PersonModel> { (18..<30).contains($0.age) })
        #expect(range == .compound(.and([
            .comparison(.init(left: .keyPath("age"), right: .attribute(.int64(18)), type: .greaterThanOrEqualTo)),
            .comparison(.init(left: .keyPath("age"), right: .attribute(.int64(30)), type: .lessThan))
        ])))
        #expect(Self.people.filtered(by: range).map(\.id.rawValue) == ["Alina"])
    }

    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    @Test func collectionModifiers() throws {

        // allSatisfy over a nested collection becomes an ALL comparison
        let all = try FetchRequest.Predicate(#Predicate<PersonModel> { $0.friends.allSatisfy { $0.age >= 18 } })
        #expect(all == .comparison(.init(
            left: .keyPath("friends.age"),
            right: .attribute(.int64(18)),
            type: .greaterThanOrEqualTo,
            modifier: .all
        )))

        // contains(where:) becomes an ANY comparison
        let any = try FetchRequest.Predicate(#Predicate<PersonModel> { $0.friends.contains { $0.name == "Bob" } })
        #expect(any == .comparison(.init(
            left: .keyPath("friends.name"),
            right: .attribute(.string("Bob")),
            type: .equalTo,
            modifier: .any
        )))

        // a compound test can't carry a modifier
        #expect(throws: FetchRequest.Predicate.ConversionError.self) {
            try FetchRequest.Predicate(#Predicate<PersonModel> { $0.friends.allSatisfy { $0.age >= 18 && $0.name != "Bob" } })
        }
    }

    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    @Test func aggregates() throws {

        let min = try FetchRequest.Predicate(#Predicate<PersonModel> { $0.scores.min() == 10 })
        #expect(min == .comparison(.init(
            left: .keyPath(PredicateKeyPath(keys: [.property("scores"), .operator(.min)])),
            right: .attribute(.int64(10)),
            type: .equalTo
        )))

        let max = try FetchRequest.Predicate(#Predicate<PersonModel> { $0.scores.max() == 100 })
        #expect(max == .comparison(.init(
            left: .keyPath(PredicateKeyPath(keys: [.property("scores"), .operator(.max)])),
            right: .attribute(.int64(100)),
            type: .equalTo
        )))
    }

    @available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, *)
    @Test func regex() throws {

        // the pattern is recovered from the regex the macro captures, and padded
        // because MATCHES matches the whole value rather than a substring
        let dynamic = try Regex("Al[a-z]+")
        let predicate = try FetchRequest.Predicate(#Predicate<PersonModel> { $0.name.contains(dynamic) })
        #expect(predicate == .comparison(.init(
            left: .keyPath("name"),
            right: .attribute(.string(".*Al[a-z]+.*")),
            type: .matches
        )))
        #expect(Self.people.filtered(by: predicate).map(\.id.rawValue) == ["Alice", "Alina"])

        // regex literals and RegexBuilder regexes carry their pattern too
        let literal = try FetchRequest.Predicate(#Predicate<PersonModel> { $0.name.contains(#/^Al/#) })
        #expect(literal == .comparison(.init(
            left: .keyPath("name"),
            right: .attribute(.string(".*^Al.*")),
            type: .matches
        )))
        #expect(Self.people.filtered(by: literal).map(\.id.rawValue) == ["Alice", "Alina"])

        // the CoreModel API expresses the same comparison directly
        let direct = "name".compare(.matches, .attribute(.string(".*Al[a-z]+.*")))
        #expect(Self.people.filtered(by: direct).map(\.id.rawValue) == ["Alice", "Alina"])
    }

    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    @Test func unsupported() {

        // subscripts have no CoreModel equivalent
        #expect(throws: FetchRequest.Predicate.ConversionError.self) {
            try FetchRequest.Predicate(#Predicate<PersonModel> { $0.scores[0] > 10 })
        }
        // nil-coalescing has no CoreModel equivalent
        #expect(throws: FetchRequest.Predicate.ConversionError.self) {
            try FetchRequest.Predicate(#Predicate<PersonModel> { ($0.nickname ?? "") == "Al" })
        }
    }

    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    @Test func fetchRequestEvaluation() throws {

        let request = FetchRequest(
            entity: "Person",
            sortDescriptors: [.init(property: "age", ascending: true)],
            predicate: try FetchRequest.Predicate(#Predicate<PersonModel> { $0.age >= 18 })
        )
        let results = request.evaluate(Self.people)
        #expect(results.map(\.id.rawValue) == ["Alina", "Alice"])
    }
}
