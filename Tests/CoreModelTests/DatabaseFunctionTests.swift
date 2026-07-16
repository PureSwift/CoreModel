//
//  DatabaseFunctionTests.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/16/26.
//

import Foundation
import Testing
@testable import CoreModel

@Suite struct DatabaseFunctionTests {

    @Test func evaluate() {
        let function = DatabaseFunction(name: "add", argumentCount: 2) { arguments in
            guard case let .int64(a) = arguments[0], case let .int64(b) = arguments[1] else {
                return nil
            }
            return .int64(a + b)
        }
        #expect(function.evaluate([.int64(2), .int64(3)]) == .int64(5))
    }

    @Test func functionExpressionCodable() throws {
        let expression = FetchRequest.Predicate.Expression.function(
            .init(name: "myFunction", arguments: [.keyPath("foo"), .attribute(.int64(42))])
        )
        let data = try JSONEncoder().encode(expression)
        let decoded = try JSONDecoder().decode(FetchRequest.Predicate.Expression.self, from: data)
        #expect(decoded == expression)
    }

    @Test func sortDescriptorFunctionTerm() throws {
        let sort = FetchRequest.SortDescriptor(
            term: .function(.init(name: "myFunction", arguments: [.keyPath("foo")])),
            ascending: false
        )
        #expect(sort.property == nil)
        let data = try JSONEncoder().encode(sort)
        let decoded = try JSONDecoder().decode(FetchRequest.SortDescriptor.self, from: data)
        #expect(decoded == sort)
    }

    @Test func sortDescriptorPropertyCompatibility() {
        let sort = FetchRequest.SortDescriptor(property: "name", ascending: true)
        #expect(sort.property == "name")
        #expect(sort.term == .property("name"))
    }
}
