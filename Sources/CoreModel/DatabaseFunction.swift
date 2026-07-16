//
//  DatabaseFunction.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/16/26.
//  Copyright © 2026 PureSwift. All rights reserved.
//

/// A custom function that can be registered with a ``ModelStorage`` so it can be
/// invoked from a ``FetchRequest/Predicate`` or ``FetchRequest/SortDescriptor`` via
/// ``FetchRequest/Predicate/Expression/function(_:)``.
///
/// Backends decide how to execute a registered function: a SQL-backed store may
/// register it directly with the underlying database engine so it can run as part
/// of a query, while other backends may call `evaluate` in memory against already
/// fetched values.
public struct DatabaseFunction: Sendable {

    /// The name used to refer to this function from a predicate or sort descriptor.
    public var name: String

    /// The number of arguments this function accepts, or `nil` if variadic.
    public var argumentCount: Int?

    /// Whether this function always returns the same result for the same arguments.
    public var deterministic: Bool

    /// Evaluates the function given its argument values, returning the result.
    public var evaluate: @Sendable ([AttributeValue?]) -> AttributeValue?

    public init(
        name: String,
        argumentCount: Int? = nil,
        deterministic: Bool = true,
        evaluate: @escaping @Sendable ([AttributeValue?]) -> AttributeValue?
    ) {
        self.name = name
        self.argumentCount = argumentCount
        self.deterministic = deterministic
        self.evaluate = evaluate
    }
}
