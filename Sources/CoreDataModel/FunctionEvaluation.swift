//
//  FunctionEvaluation.swift
//  CoreDataModel
//
//  Created by Alsey Coleman Miller on 7/16/26.
//

#if canImport(CoreData)
import Foundation
import CoreModel

// MARK: - Function detection

internal extension FetchRequest {

    /// Whether this fetch request references any custom `.function` expression and
    /// therefore requires in-memory evaluation — CoreData cannot execute a custom
    /// function as part of a native fetch.
    var requiresInMemoryEvaluation: Bool {
        if predicate?.containsFunction == true {
            return true
        }
        return sortDescriptors.contains { descriptor in
            if case .function = descriptor.term { return true } else { return false }
        }
    }
}

internal extension FetchRequest.Predicate {

    /// Whether this predicate references any `.function` expression.
    var containsFunction: Bool {
        switch self {
        case .value:
            return false
        case let .comparison(comparison):
            return comparison.left.containsFunction || comparison.right.containsFunction
        case let .compound(compound):
            return compound.subpredicates.contains { $0.containsFunction }
        }
    }

    /// Replace every comparison that references a function with `.value(true)`, so the
    /// remaining predicate can be evaluated natively by CoreData as a superset filter.
    /// The full predicate is then re-applied in memory.
    func strippingFunctionComparisons() -> FetchRequest.Predicate {
        switch self {
        case .value:
            return self
        case let .comparison(comparison):
            let usesFunction = comparison.left.containsFunction || comparison.right.containsFunction
            return usesFunction ? .value(true) : self
        case let .compound(compound):
            switch compound {
            case let .and(subpredicates):
                return .compound(.and(subpredicates.map { $0.strippingFunctionComparisons() }))
            case let .or(subpredicates):
                return .compound(.or(subpredicates.map { $0.strippingFunctionComparisons() }))
            case let .not(subpredicate):
                return .compound(.not(subpredicate.strippingFunctionComparisons()))
            }
        }
    }
}

internal extension FetchRequest.Predicate.Expression {

    var containsFunction: Bool {
        switch self {
        case .function:
            return true
        case .attribute, .relationship, .keyPath:
            return false
        }
    }
}

#endif
