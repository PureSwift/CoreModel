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

// MARK: - In-memory evaluation

internal extension FetchRequest.Predicate {

    /// Evaluate this predicate against a fetched object in memory, calling registered
    /// functions for any `.function` expression.
    func evaluate(
        with data: ModelData,
        functions: [String: DatabaseFunction]
    ) -> Bool {
        switch self {
        case let .value(value):
            return value
        case let .compound(compound):
            switch compound {
            case let .and(subpredicates):
                return subpredicates.allSatisfy { $0.evaluate(with: data, functions: functions) }
            case let .or(subpredicates):
                return subpredicates.contains { $0.evaluate(with: data, functions: functions) }
            case let .not(subpredicate):
                return subpredicate.evaluate(with: data, functions: functions) == false
            }
        case let .comparison(comparison):
            return comparison.evaluate(with: data, functions: functions)
        }
    }
}

internal extension FetchRequest.Predicate.Comparison {

    func evaluate(
        with data: ModelData,
        functions: [String: DatabaseFunction]
    ) -> Bool {
        let lhs = left.evaluate(with: data, functions: functions)
        let rhs = right.evaluate(with: data, functions: functions)
        return type.evaluate(lhs, rhs, options: options)
    }
}

internal extension FetchRequest.Predicate.Expression {

    /// Resolve this expression to a value for a fetched object.
    func evaluate(
        with data: ModelData,
        functions: [String: DatabaseFunction]
    ) -> AttributeValue? {
        switch self {
        case let .attribute(value):
            return value
        case let .keyPath(keyPath):
            return data.attributes[PropertyKey(rawValue: keyPath.rawValue)]
        case let .function(function):
            guard let registered = functions[function.name] else {
                return nil
            }
            let arguments = function.arguments.map { $0.evaluate(with: data, functions: functions) }
            return registered.evaluate(arguments)
        case .relationship:
            // relationships aren't compared by the in-memory function path
            return nil
        }
    }
}

// MARK: - Operator evaluation

private extension FetchRequest.Predicate.Comparison.Operator {

    func evaluate(
        _ lhs: AttributeValue?,
        _ rhs: AttributeValue?,
        options: Set<FetchRequest.Predicate.Comparison.Option>
    ) -> Bool {
        let caseInsensitive = options.contains(.caseInsensitive)
        switch self {
        case .equalTo:
            return AttributeValue.areEqual(lhs, rhs, caseInsensitive: caseInsensitive)
        case .notEqualTo:
            return AttributeValue.areEqual(lhs, rhs, caseInsensitive: caseInsensitive) == false
        case .lessThan:
            return (AttributeValue.order(lhs, rhs)).map { $0 < 0 } ?? false
        case .lessThanOrEqualTo:
            return (AttributeValue.order(lhs, rhs)).map { $0 <= 0 } ?? false
        case .greaterThan:
            return (AttributeValue.order(lhs, rhs)).map { $0 > 0 } ?? false
        case .greaterThanOrEqualTo:
            return (AttributeValue.order(lhs, rhs)).map { $0 >= 0 } ?? false
        case .beginsWith:
            return AttributeValue.stringCompare(lhs, rhs, caseInsensitive: caseInsensitive) { $0.hasPrefix($1) }
        case .endsWith:
            return AttributeValue.stringCompare(lhs, rhs, caseInsensitive: caseInsensitive) { $0.hasSuffix($1) }
        case .contains:
            return AttributeValue.stringCompare(lhs, rhs, caseInsensitive: caseInsensitive) { $0.contains($1) }
        case .like, .matches:
            return AttributeValue.stringCompare(lhs, rhs, caseInsensitive: caseInsensitive) { subject, pattern in
                subject.range(of: like(pattern: pattern, matches: self == .matches), options: .regularExpression) != nil
            }
        case .in, .between:
            // right-hand collections aren't represented as a single AttributeValue
            return false
        }
    }

    /// Convert a Cocoa-style `LIKE` pattern (`*`, `?`) or a full regular expression into
    /// an anchored regular expression string.
    private func like(pattern: String, matches: Bool) -> String {
        guard matches == false else {
            return pattern // already a regular expression
        }
        let escaped = NSRegularExpression.escapedPattern(for: pattern)
            .replacingOccurrences(of: "\\*", with: ".*")
            .replacingOccurrences(of: "\\?", with: ".")
        return "^" + escaped + "$"
    }
}

private extension AttributeValue {

    /// A numeric representation for comparable value types, for ordering comparisons.
    var comparableDouble: Double? {
        switch self {
        case let .bool(value):      return value ? 1 : 0
        case let .int16(value):     return Double(value)
        case let .int32(value):     return Double(value)
        case let .int64(value):     return Double(value)
        case let .float(value):     return Double(value)
        case let .double(value):    return value
        case let .decimal(value):   return NSDecimalNumber(decimal: value).doubleValue
        case let .date(value):      return value.timeIntervalSinceReferenceDate
        default:                    return nil
        }
    }

    var stringValue: String? {
        if case let .string(value) = self { return value }
        return nil
    }

    static func areEqual(_ lhs: AttributeValue?, _ rhs: AttributeValue?, caseInsensitive: Bool) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none), (.some(.null), .none), (.none, .some(.null)), (.some(.null), .some(.null)):
            return true
        case let (.some(left), .some(right)):
            if caseInsensitive, let l = left.stringValue, let r = right.stringValue {
                return l.caseInsensitiveCompare(r) == .orderedSame
            }
            return left == right
        default:
            return false
        }
    }

    /// Ordering of two values: negative if `lhs < rhs`, zero if equal, positive if greater;
    /// `nil` if the values aren't order-comparable.
    static func order(_ lhs: AttributeValue?, _ rhs: AttributeValue?) -> Int? {
        guard let lhs, let rhs else { return nil }
        if let l = lhs.comparableDouble, let r = rhs.comparableDouble {
            if l < r { return -1 }
            if l > r { return 1 }
            return 0
        }
        if let l = lhs.stringValue, let r = rhs.stringValue {
            switch l.compare(r) {
            case .orderedAscending:  return -1
            case .orderedSame:       return 0
            case .orderedDescending: return 1
            }
        }
        return nil
    }

    static func stringCompare(
        _ lhs: AttributeValue?,
        _ rhs: AttributeValue?,
        caseInsensitive: Bool,
        _ compare: (String, String) -> Bool
    ) -> Bool {
        guard var subject = lhs?.stringValue, var pattern = rhs?.stringValue else {
            return false
        }
        if caseInsensitive {
            subject = subject.lowercased()
            pattern = pattern.lowercased()
        }
        return compare(subject, pattern)
    }
}

// MARK: - In-memory sorting

internal extension Array where Element == ModelData {

    /// Sort in memory by the given descriptors, resolving function terms with the
    /// registered functions. Property terms fall back to attribute ordering.
    func sortedInMemory(
        by sortDescriptors: [FetchRequest.SortDescriptor],
        functions: [String: DatabaseFunction]
    ) -> [ModelData] {
        guard sortDescriptors.isEmpty == false else { return self }
        return sorted { first, second in
            for descriptor in sortDescriptors {
                let lhs: AttributeValue?
                let rhs: AttributeValue?
                switch descriptor.term {
                case let .property(property):
                    lhs = first.attributes[property]
                    rhs = second.attributes[property]
                case let .function(function):
                    let expression = FetchRequest.Predicate.Expression.function(function)
                    lhs = expression.evaluate(with: first, functions: functions)
                    rhs = expression.evaluate(with: second, functions: functions)
                }
                guard let comparison = AttributeValue.order(lhs, rhs), comparison != 0 else {
                    continue
                }
                return descriptor.ascending ? comparison < 0 : comparison > 0
            }
            // stable tiebreaker on id, matching the native fetch's trailing id sort
            return first.id.rawValue < second.id.rawValue
        }
    }
}

#endif
