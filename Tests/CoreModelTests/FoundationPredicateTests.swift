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
    @Test func unsupported() {

        // arithmetic has no CoreModel equivalent
        #expect(throws: FetchRequest.Predicate.ConversionError.self) {
            try FetchRequest.Predicate(#Predicate<PersonModel> { $0.age + 1 > 18 })
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
