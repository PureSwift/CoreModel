//
//  FunctionEvaluationTests.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/17/25.
//

#if canImport(CoreData)

import Foundation
import Testing
@testable import CoreModel
@testable import CoreDataModel

@Suite struct FunctionEvaluationTests {

    typealias Predicate = FetchRequest.Predicate

    static let lowercase = DatabaseFunction(name: "lowercase", argumentCount: 1) { arguments in
        guard case let .string(value) = arguments[0] else { return nil }
        return .string(value.lowercased())
    }

    static let functions = ["lowercase": lowercase]

    static let functionExpression = Predicate.Expression.function(
        .init(name: "lowercase", arguments: [.keyPath("name")])
    )

    static func makeData(name: String = "Alice", age: Int64 = 30, id: String = "1") -> ModelData {
        ModelData(
            entity: "Person",
            id: ObjectID(rawValue: id),
            attributes: ["name": .string(name), "age": .int64(age)]
        )
    }

    @Test func requiresInMemoryEvaluation() {
        let native = FetchRequest(entity: "Person", predicate: "name".compare(.equalTo, .attribute(.string("x"))))
        #expect(native.requiresInMemoryEvaluation == false)
        let functionPredicate = FetchRequest(
            entity: "Person",
            predicate: Self.functionExpression.compare(.equalTo, .attribute(.string("x")))
        )
        #expect(functionPredicate.requiresInMemoryEvaluation)
        let functionSort = FetchRequest(
            entity: "Person",
            sortDescriptors: [.init(term: .function(.init(name: "lowercase", arguments: [.keyPath("name")])), ascending: true)]
        )
        #expect(functionSort.requiresInMemoryEvaluation)
    }

    @Test func containsFunction() {
        #expect(Predicate.value(true).containsFunction == false)
        #expect("name".compare(.equalTo, .attribute(.string("x"))).containsFunction == false)
        #expect(Self.functionExpression.compare(.equalTo, .attribute(.string("x"))).containsFunction)
        // function on the right side
        #expect(Predicate.Expression.keyPath("name").compare(.equalTo, Self.functionExpression).containsFunction)
        #expect(Predicate.compound(.and([.value(true), Self.functionExpression.compare(.equalTo, .attribute(.null))])).containsFunction)
        #expect(Predicate.compound(.or([.value(false)])).containsFunction == false)
    }

    @Test func strippingFunctionComparisons() {
        let function = Self.functionExpression.compare(.equalTo, .attribute(.string("x")))
        let native = "name".compare(.equalTo, .attribute(.string("x")))
        #expect(Predicate.value(false).strippingFunctionComparisons() == .value(false))
        #expect(native.strippingFunctionComparisons() == native)
        #expect(function.strippingFunctionComparisons() == .value(true))
        #expect(
            Predicate.compound(.and([native, function])).strippingFunctionComparisons()
                == .compound(.and([native, .value(true)]))
        )
        #expect(
            Predicate.compound(.or([function])).strippingFunctionComparisons()
                == .compound(.or([.value(true)]))
        )
        #expect(
            Predicate.compound(.not(function)).strippingFunctionComparisons()
                == .compound(.not(.value(true)))
        )
    }

    @Test func predicateEvaluation() {
        let data = Self.makeData()
        #expect(Predicate.value(true).evaluate(with: data, functions: [:]))
        #expect(Predicate.value(false).evaluate(with: data, functions: [:]) == false)
        let isAlice = Self.functionExpression.compare(.equalTo, .attribute(.string("alice")))
        #expect(isAlice.evaluate(with: data, functions: Self.functions))
        // compound evaluation
        #expect(Predicate.compound(.and([.value(true), isAlice])).evaluate(with: data, functions: Self.functions))
        #expect(Predicate.compound(.and([.value(false), isAlice])).evaluate(with: data, functions: Self.functions) == false)
        #expect(Predicate.compound(.or([.value(false), isAlice])).evaluate(with: data, functions: Self.functions))
        #expect(Predicate.compound(.not(isAlice)).evaluate(with: data, functions: Self.functions) == false)
    }

    @Test func expressionEvaluation() {
        let data = Self.makeData()
        #expect(Predicate.Expression.attribute(.int64(1)).evaluate(with: data, functions: [:]) == .attribute(.int64(1)))
        #expect(Predicate.Expression.keyPath("name").evaluate(with: data, functions: [:]) == .attribute(.string("Alice")))
        #expect(Predicate.Expression.keyPath("missing").evaluate(with: data, functions: [:]) == nil)
        #expect(Self.functionExpression.evaluate(with: data, functions: Self.functions) == .attribute(.string("alice")))
        // unregistered function
        #expect(Self.functionExpression.evaluate(with: data, functions: [:]) == nil)
        // relationship expressions resolve to relationship values
        #expect(Predicate.Expression.relationship(.toOne("x")).evaluate(with: data, functions: [:]) == .relationship(.toOne("x")))
    }

    @Test func operatorEvaluation() {
        let data = Self.makeData()
        func evaluate(
            _ type: Predicate.Comparison.Operator,
            _ lhs: Predicate.Expression,
            _ rhs: Predicate.Expression,
            options: Set<Predicate.Comparison.Option> = []
        ) -> Bool {
            Predicate.comparison(.init(left: lhs, right: rhs, type: type, options: options))
                .evaluate(with: data, functions: Self.functions)
        }
        let name = Predicate.Expression.keyPath("name")
        let age = Predicate.Expression.keyPath("age")
        // equality
        #expect(evaluate(.equalTo, name, .attribute(.string("Alice"))))
        #expect(evaluate(.equalTo, name, .attribute(.string("ALICE")), options: [.caseInsensitive]))
        #expect(evaluate(.equalTo, name, .attribute(.string("ALICE"))) == false)
        #expect(evaluate(.notEqualTo, name, .attribute(.string("Bob"))))
        // null equality
        #expect(evaluate(.equalTo, .attribute(.null), .attribute(.null)))
        #expect(evaluate(.equalTo, .keyPath("missing"), .attribute(.null)))
        #expect(evaluate(.equalTo, name, .attribute(.null)) == false)
        #expect(evaluate(.equalTo, name, .keyPath("missing")) == false)
        // ordering (numeric)
        #expect(evaluate(.lessThan, age, .attribute(.int64(40))))
        #expect(evaluate(.lessThan, age, .attribute(.int64(30))) == false)
        #expect(evaluate(.lessThanOrEqualTo, age, .attribute(.int64(30))))
        #expect(evaluate(.greaterThan, age, .attribute(.int64(20))))
        #expect(evaluate(.greaterThanOrEqualTo, age, .attribute(.int64(30))))
        // ordering with mixed numeric types
        #expect(evaluate(.lessThan, age, .attribute(.double(30.5))))
        #expect(evaluate(.greaterThan, age, .attribute(.float(29.5))))
        #expect(evaluate(.greaterThan, age, .attribute(.int16(29))))
        #expect(evaluate(.lessThan, age, .attribute(.int32(31))))
        #expect(evaluate(.greaterThan, age, .attribute(.bool(true))))
        #expect(evaluate(.lessThan, age, .attribute(.decimal(Decimal(50)))))
        // date ordering
        #expect(evaluate(.lessThan, .attribute(.date(Date(timeIntervalSinceReferenceDate: 0))), .attribute(.date(Date(timeIntervalSinceReferenceDate: 100)))))
        // string ordering
        #expect(evaluate(.lessThan, name, .attribute(.string("Bob"))))
        #expect(evaluate(.greaterThan, name, .attribute(.string("Bob"))) == false)
        // non-comparable ordering
        #expect(evaluate(.lessThan, name, .attribute(.int64(1))) == false)
        #expect(evaluate(.lessThan, .attribute(.null), age) == false)
        // string operators
        #expect(evaluate(.beginsWith, name, .attribute(.string("Al"))))
        #expect(evaluate(.beginsWith, name, .attribute(.string("AL")), options: [.caseInsensitive]))
        #expect(evaluate(.endsWith, name, .attribute(.string("ice"))))
        #expect(evaluate(.contains, name, .attribute(.string("lic"))))
        #expect(evaluate(.contains, name, .attribute(.string("bob"))) == false)
        #expect(evaluate(.contains, age, .attribute(.string("3"))) == false)
        // like / matches
        #expect(evaluate(.like, name, .attribute(.string("A*e"))))
        #expect(evaluate(.like, name, .attribute(.string("Alic?"))))
        #expect(evaluate(.like, name, .attribute(.string("B*"))) == false)
        #expect(evaluate(.matches, name, .attribute(.string("^A[a-z]+e$"))))
        #expect(evaluate(.matches, name, .attribute(.string("^[0-9]+$"))) == false)
        // IN: left hand side is a substring of the right hand side
        #expect(evaluate(.in, name, .attribute(.string("Alice in Wonderland"))))
        #expect(evaluate(.in, name, .attribute(.string("Bob"))) == false)
        // BETWEEN bounds aren't representable as a single expression value
        #expect(evaluate(.between, age, .attribute(.int64(50))) == false)
    }

    @Test func sortedInMemory() {
        let people = [
            Self.makeData(name: "Charlie", age: 35, id: "3"),
            Self.makeData(name: "alice", age: 30, id: "1"),
            Self.makeData(name: "Bob", age: 30, id: "2")
        ]
        // no descriptors sorts by identifier
        #expect(people.sorted(by: [], functions: [:]).map { $0.id.rawValue } == ["1", "2", "3"])
        // property ascending
        let byAge = people.sorted(by: [.init(property: "age", ascending: true)], functions: [:])
        #expect(byAge.map { $0.id.rawValue } == ["1", "2", "3"])
        // property descending
        let byAgeDesc = people.sorted(by: [.init(property: "age", ascending: false)], functions: [:])
        #expect(byAgeDesc.first?.id.rawValue == "3")
        // function term (case-insensitive name order)
        let byName = people.sorted(
            by: [.init(term: .function(.init(name: "lowercase", arguments: [.keyPath("name")])), ascending: true)],
            functions: Self.functions
        )
        #expect(byName.map { $0.id.rawValue } == ["1", "2", "3"])
        // ties fall back to id ordering
        let tied = people.sorted(by: [.init(property: "missing", ascending: true)], functions: [:])
        #expect(tied.map { $0.id.rawValue } == ["1", "2", "3"])
    }
}

#endif
