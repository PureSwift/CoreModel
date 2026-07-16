//
//  FunctionExpression.swift
//  Predicate
//
//  Created by Alsey Coleman Miller on 7/16/26.
//  Copyright © 2026 PureSwift. All rights reserved.
//

public extension FetchRequest.Predicate {

    /// Represents a call to a named function (e.g. a custom function registered
    /// with the underlying store via ``DatabaseFunction``) with a list of argument expressions.
    struct FunctionExpression: Equatable, Hashable, Sendable {

        /// The name of the function to invoke.
        public var name: String

        /// The arguments passed to the function.
        public var arguments: [FetchRequest.Predicate.Expression]

        public init(name: String, arguments: [FetchRequest.Predicate.Expression]) {
            self.name = name
            self.arguments = arguments
        }
    }
}

#if !hasFeature(Embedded)
extension FetchRequest.Predicate.FunctionExpression: Codable {}
#endif

// MARK: - CustomStringConvertible

extension FetchRequest.Predicate.FunctionExpression: CustomStringConvertible {

    public var description: String {
        name + "(" + arguments.map { $0.description }.joined(separator: ", ") + ")"
    }
}
