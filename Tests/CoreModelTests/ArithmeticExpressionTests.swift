//
//  ArithmeticExpressionTests.swift
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

@Suite struct ArithmeticExpressionTests {

    static var person: ModelData {
        ModelData(
            entity: "Person",
            id: ObjectID(rawValue: "1"),
            attributes: [
                "name": .string("Alice"),
                "age": .int64(30),
                "height": .double(1.7)
            ]
        )
    }

    @Test func description() {

        let expression = FetchRequest.Predicate.Expression.arithmetic(
            .init(function: .add, left: .keyPath("age"), right: .attribute(.int64(1)))
        )
        #expect(expression.description == "(age + 1)")
        #expect(FetchRequest.Predicate.ArithmeticExpression.Function.allCases.map(\.symbol) == ["+", "-", "*", "/", "%"])
    }

    @Test func evaluation() {

        let person = Self.person

        // integer arithmetic stays integral
        let add = FetchRequest.Predicate.Expression.arithmetic(
            .init(function: .add, left: .keyPath("age"), right: .attribute(.int64(5)))
        )
        #expect(add.compare(.equalTo, .attribute(.int64(35))).evaluate(with: person))

        let subtract = FetchRequest.Predicate.Expression.arithmetic(
            .init(function: .subtract, left: .keyPath("age"), right: .attribute(.int64(12)))
        )
        #expect(subtract.compare(.lessThan, .attribute(.int64(19))).evaluate(with: person))

        let multiply = FetchRequest.Predicate.Expression.arithmetic(
            .init(function: .multiply, left: .keyPath("age"), right: .attribute(.int64(2)))
        )
        #expect(multiply.compare(.equalTo, .attribute(.int64(60))).evaluate(with: person))

        let modulus = FetchRequest.Predicate.Expression.arithmetic(
            .init(function: .modulus, left: .keyPath("age"), right: .attribute(.int64(7)))
        )
        #expect(modulus.compare(.equalTo, .attribute(.int64(2))).evaluate(with: person))

        // integer division truncates, the way Swift's `/` and NSExpression's `divide:by:` do
        let divide = FetchRequest.Predicate.Expression.arithmetic(
            .init(function: .divide, left: .keyPath("age"), right: .attribute(.int64(4)))
        )
        #expect(divide.compare(.equalTo, .attribute(.int64(7))).evaluate(with: person)) // 30 / 4 == 7
        #expect(divide.compare(.equalTo, .attribute(.double(7.5))).evaluate(with: person) == false)

        // a floating-point operand divides normally
        let floatDivide = FetchRequest.Predicate.Expression.arithmetic(
            .init(function: .divide, left: .keyPath("height"), right: .attribute(.int64(2)))
        )
        #expect(floatDivide.compare(.equalTo, .attribute(.double(0.85))).evaluate(with: person))

        // mixed integer and floating-point operands promote to double
        let mixed = FetchRequest.Predicate.Expression.arithmetic(
            .init(function: .multiply, left: .keyPath("height"), right: .attribute(.int64(100)))
        )
        #expect(mixed.compare(.greaterThan, .attribute(.double(169))).evaluate(with: person))

        // nested arithmetic: (age + 2) * 2 == 64
        let nested = FetchRequest.Predicate.Expression.arithmetic(
            .init(
                function: .multiply,
                left: .arithmetic(.init(function: .add, left: .keyPath("age"), right: .attribute(.int64(2)))),
                right: .attribute(.int64(2))
            )
        )
        #expect(nested.compare(.equalTo, .attribute(.int64(64))).evaluate(with: person))
    }

    @Test func invalidOperands() {

        let person = Self.person

        // division by zero resolves to nil and never satisfies a comparison
        let divideByZero = FetchRequest.Predicate.Expression.arithmetic(
            .init(function: .divide, left: .keyPath("age"), right: .attribute(.int64(0)))
        )
        #expect(divideByZero.compare(.equalTo, .attribute(.int64(0))).evaluate(with: person) == false)
        #expect(divideByZero.compare(.greaterThanOrEqualTo, .attribute(.int64(0))).evaluate(with: person) == false)

        // non-numeric operands resolve to nil
        let string = FetchRequest.Predicate.Expression.arithmetic(
            .init(function: .add, left: .keyPath("name"), right: .attribute(.int64(1)))
        )
        #expect(string.compare(.equalTo, .attribute(.int64(1))).evaluate(with: person) == false)

        // floating-point remainder is unsupported
        let floatModulus = FetchRequest.Predicate.Expression.arithmetic(
            .init(function: .modulus, left: .keyPath("height"), right: .attribute(.int64(2)))
        )
        #expect(floatModulus.compare(.lessThan, .attribute(.int64(2))).evaluate(with: person) == false)

        // remainder by zero resolves to nil rather than trapping
        let modulusByZero = FetchRequest.Predicate.Expression.arithmetic(
            .init(function: .modulus, left: .keyPath("age"), right: .attribute(.int64(0)))
        )
        #expect(modulusByZero.compare(.equalTo, .attribute(.int64(0))).evaluate(with: person) == false)

        // an overflowing division resolves to nil rather than trapping
        let overflow = ModelData(
            entity: "Person",
            id: ObjectID(rawValue: "overflow"),
            attributes: ["age": .int64(.min)]
        )
        let overflowingDivide = FetchRequest.Predicate.Expression.arithmetic(
            .init(function: .divide, left: .keyPath("age"), right: .attribute(.int64(-1)))
        )
        #expect(overflowingDivide.compare(.equalTo, .attribute(.int64(.min))).evaluate(with: overflow) == false)
        let overflowingModulus = FetchRequest.Predicate.Expression.arithmetic(
            .init(function: .modulus, left: .keyPath("age"), right: .attribute(.int64(-1)))
        )
        #expect(overflowingModulus.compare(.equalTo, .attribute(.int64(0))).evaluate(with: overflow) == false)
    }

    @Test func integerDivisionTruncates() {

        // every quotient truncates toward zero, matching Swift's `/`
        for (dividend, divisor) in [(7, 2), (-7, 2), (7, -2), (-7, -2), (30, 4), (1, 2)] {
            let data = ModelData(
                entity: "Person",
                id: ObjectID(rawValue: "\(dividend)"),
                attributes: ["value": .int64(numericCast(dividend))]
            )
            let expression = FetchRequest.Predicate.Expression.arithmetic(
                .init(function: .divide, left: .keyPath("value"), right: .attribute(.int64(numericCast(divisor))))
            )
            let expected = Int64(dividend / divisor)
            #expect(
                expression.compare(.equalTo, .attribute(.int64(expected))).evaluate(with: data),
                "\(dividend) / \(divisor) should be \(expected)"
            )
        }
    }

    @Test func fetchRequestEvaluation() {

        let people = [
            ("Alice", 30),
            ("Bob", 17),
            ("Alina", 20)
        ].map { name, age in
            ModelData(
                entity: "Person",
                id: ObjectID(rawValue: name),
                attributes: ["age": .int64(numericCast(age))]
            )
        }
        // age * 2 >= 40
        let predicate = FetchRequest.Predicate.Expression
            .arithmetic(.init(function: .multiply, left: .keyPath("age"), right: .attribute(.int64(2))))
            .compare(.greaterThanOrEqualTo, .attribute(.int64(40)))
        let request = FetchRequest(entity: "Person", predicate: predicate)
        #expect(request.evaluate(people).map(\.id.rawValue) == ["Alice", "Alina"])
    }

    #if !hasFeature(Embedded)
    @Test func codable() throws {

        let predicate = FetchRequest.Predicate.Expression
            .arithmetic(.init(function: .add, left: .keyPath("age"), right: .attribute(.int64(1))))
            .compare(.greaterThan, .attribute(.int64(18)))
        let encoded = try JSONEncoder().encode(predicate)
        let decoded = try JSONDecoder().decode(FetchRequest.Predicate.self, from: encoded)
        #expect(decoded == predicate)
    }
    #endif
}
