//
//  FunctionEvaluationTests.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/17/25.
//

#if canImport(CoreData)

import Foundation
import XCTest
@testable import CoreModel
@testable import CoreDataModel

final class FunctionEvaluationTests: XCTestCase {

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

    func testRequiresInMemoryEvaluation() {
        let native = FetchRequest(entity: "Person", predicate: "name".compare(.equalTo, .attribute(.string("x"))))
        XCTAssertFalse(native.requiresInMemoryEvaluation)
        let functionPredicate = FetchRequest(
            entity: "Person",
            predicate: Self.functionExpression.compare(.equalTo, .attribute(.string("x")))
        )
        XCTAssert(functionPredicate.requiresInMemoryEvaluation)
        let functionSort = FetchRequest(
            entity: "Person",
            sortDescriptors: [.init(term: .function(.init(name: "lowercase", arguments: [.keyPath("name")])), ascending: true)]
        )
        XCTAssert(functionSort.requiresInMemoryEvaluation)
    }

    func testContainsFunction() {
        XCTAssertFalse(Predicate.value(true).containsFunction)
        XCTAssertFalse("name".compare(.equalTo, .attribute(.string("x"))).containsFunction)
        XCTAssert(Self.functionExpression.compare(.equalTo, .attribute(.string("x"))).containsFunction)
        // function on the right side
        XCTAssert(Predicate.Expression.keyPath("name").compare(.equalTo, Self.functionExpression).containsFunction)
        XCTAssert(Predicate.compound(.and([.value(true), Self.functionExpression.compare(.equalTo, .attribute(.null))])).containsFunction)
        XCTAssertFalse(Predicate.compound(.or([.value(false)])).containsFunction)
    }

    func testStrippingFunctionComparisons() {
        let function = Self.functionExpression.compare(.equalTo, .attribute(.string("x")))
        let native = "name".compare(.equalTo, .attribute(.string("x")))
        XCTAssertEqual(Predicate.value(false).strippingFunctionComparisons(), .value(false))
        XCTAssertEqual(native.strippingFunctionComparisons(), native)
        XCTAssertEqual(function.strippingFunctionComparisons(), .value(true))
        XCTAssertEqual(
            Predicate.compound(.and([native, function])).strippingFunctionComparisons(),
            .compound(.and([native, .value(true)]))
        )
        XCTAssertEqual(
            Predicate.compound(.or([function])).strippingFunctionComparisons(),
            .compound(.or([.value(true)]))
        )
        XCTAssertEqual(
            Predicate.compound(.not(function)).strippingFunctionComparisons(),
            .compound(.not(.value(true)))
        )
    }

    func testPredicateEvaluation() {
        let data = Self.makeData()
        XCTAssert(Predicate.value(true).evaluate(with: data, functions: [:]))
        XCTAssertFalse(Predicate.value(false).evaluate(with: data, functions: [:]))
        let isAlice = Self.functionExpression.compare(.equalTo, .attribute(.string("alice")))
        XCTAssert(isAlice.evaluate(with: data, functions: Self.functions))
        // compound evaluation
        XCTAssert(Predicate.compound(.and([.value(true), isAlice])).evaluate(with: data, functions: Self.functions))
        XCTAssertFalse(Predicate.compound(.and([.value(false), isAlice])).evaluate(with: data, functions: Self.functions))
        XCTAssert(Predicate.compound(.or([.value(false), isAlice])).evaluate(with: data, functions: Self.functions))
        XCTAssertFalse(Predicate.compound(.not(isAlice)).evaluate(with: data, functions: Self.functions))
    }

    func testExpressionEvaluation() {
        let data = Self.makeData()
        XCTAssertEqual(Predicate.Expression.attribute(.int64(1)).evaluate(with: data, functions: [:]), .int64(1))
        XCTAssertEqual(Predicate.Expression.keyPath("name").evaluate(with: data, functions: [:]), .string("Alice"))
        XCTAssertNil(Predicate.Expression.keyPath("missing").evaluate(with: data, functions: [:]))
        XCTAssertEqual(Self.functionExpression.evaluate(with: data, functions: Self.functions), .string("alice"))
        // unregistered function
        XCTAssertNil(Self.functionExpression.evaluate(with: data, functions: [:]))
        // relationships aren't evaluated
        XCTAssertNil(Predicate.Expression.relationship(.toOne("x")).evaluate(with: data, functions: [:]))
    }

    func testOperatorEvaluation() {
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
        XCTAssert(evaluate(.equalTo, name, .attribute(.string("Alice"))))
        XCTAssert(evaluate(.equalTo, name, .attribute(.string("ALICE")), options: [.caseInsensitive]))
        XCTAssertFalse(evaluate(.equalTo, name, .attribute(.string("ALICE"))))
        XCTAssert(evaluate(.notEqualTo, name, .attribute(.string("Bob"))))
        // null equality
        XCTAssert(evaluate(.equalTo, .attribute(.null), .attribute(.null)))
        XCTAssert(evaluate(.equalTo, .keyPath("missing"), .attribute(.null)))
        XCTAssertFalse(evaluate(.equalTo, name, .attribute(.null)))
        XCTAssertFalse(evaluate(.equalTo, name, .keyPath("missing")))
        // ordering (numeric)
        XCTAssert(evaluate(.lessThan, age, .attribute(.int64(40))))
        XCTAssertFalse(evaluate(.lessThan, age, .attribute(.int64(30))))
        XCTAssert(evaluate(.lessThanOrEqualTo, age, .attribute(.int64(30))))
        XCTAssert(evaluate(.greaterThan, age, .attribute(.int64(20))))
        XCTAssert(evaluate(.greaterThanOrEqualTo, age, .attribute(.int64(30))))
        // ordering with mixed numeric types
        XCTAssert(evaluate(.lessThan, age, .attribute(.double(30.5))))
        XCTAssert(evaluate(.greaterThan, age, .attribute(.float(29.5))))
        XCTAssert(evaluate(.greaterThan, age, .attribute(.int16(29))))
        XCTAssert(evaluate(.lessThan, age, .attribute(.int32(31))))
        XCTAssert(evaluate(.greaterThan, age, .attribute(.bool(true))))
        XCTAssert(evaluate(.lessThan, age, .attribute(.decimal(Decimal(50)))))
        // date ordering
        XCTAssert(evaluate(.lessThan, .attribute(.date(Date(timeIntervalSinceReferenceDate: 0))), .attribute(.date(Date(timeIntervalSinceReferenceDate: 100)))))
        // string ordering
        XCTAssert(evaluate(.lessThan, name, .attribute(.string("Bob"))))
        XCTAssertFalse(evaluate(.greaterThan, name, .attribute(.string("Bob"))))
        // non-comparable ordering
        XCTAssertFalse(evaluate(.lessThan, name, .attribute(.int64(1))))
        XCTAssertFalse(evaluate(.lessThan, .attribute(.null), age))
        // string operators
        XCTAssert(evaluate(.beginsWith, name, .attribute(.string("Al"))))
        XCTAssert(evaluate(.beginsWith, name, .attribute(.string("AL")), options: [.caseInsensitive]))
        XCTAssert(evaluate(.endsWith, name, .attribute(.string("ice"))))
        XCTAssert(evaluate(.contains, name, .attribute(.string("lic"))))
        XCTAssertFalse(evaluate(.contains, name, .attribute(.string("bob"))))
        XCTAssertFalse(evaluate(.contains, age, .attribute(.string("3"))))
        // like / matches
        XCTAssert(evaluate(.like, name, .attribute(.string("A*e"))))
        XCTAssert(evaluate(.like, name, .attribute(.string("Alic?"))))
        XCTAssertFalse(evaluate(.like, name, .attribute(.string("B*"))))
        XCTAssert(evaluate(.matches, name, .attribute(.string("^A[a-z]+e$"))))
        XCTAssertFalse(evaluate(.matches, name, .attribute(.string("^[0-9]+$"))))
        // unsupported collection operators
        XCTAssertFalse(evaluate(.in, name, .attribute(.string("Alice"))))
        XCTAssertFalse(evaluate(.between, age, .attribute(.int64(50))))
    }

    func testSortedInMemory() {
        let people = [
            Self.makeData(name: "Charlie", age: 35, id: "3"),
            Self.makeData(name: "alice", age: 30, id: "1"),
            Self.makeData(name: "Bob", age: 30, id: "2")
        ]
        // no descriptors returns as-is
        XCTAssertEqual(people.sortedInMemory(by: [], functions: [:]), people)
        // property ascending
        let byAge = people.sortedInMemory(by: [.init(property: "age", ascending: true)], functions: [:])
        XCTAssertEqual(byAge.map { $0.id.rawValue }, ["1", "2", "3"])
        // property descending
        let byAgeDesc = people.sortedInMemory(by: [.init(property: "age", ascending: false)], functions: [:])
        XCTAssertEqual(byAgeDesc.first?.id.rawValue, "3")
        // function term (case-insensitive name order)
        let byName = people.sortedInMemory(
            by: [.init(term: .function(.init(name: "lowercase", arguments: [.keyPath("name")])), ascending: true)],
            functions: Self.functions
        )
        XCTAssertEqual(byName.map { $0.id.rawValue }, ["1", "2", "3"])
        // ties fall back to id ordering
        let tied = people.sortedInMemory(by: [.init(property: "missing", ascending: true)], functions: [:])
        XCTAssertEqual(tied.map { $0.id.rawValue }, ["1", "2", "3"])
    }
}

#endif
