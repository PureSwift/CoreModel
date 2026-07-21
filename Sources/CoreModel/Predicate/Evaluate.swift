//
//  Evaluate.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/21/26.
//  Copyright © 2026 PureSwift. All rights reserved.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#elseif canImport(FoundationEmbedded)
import FoundationEmbedded
#endif

// MARK: - Predicate Evaluation

public extension FetchRequest.Predicate {

    /// Evaluate this predicate against an object in memory.
    ///
    /// This is a pure Swift filtering engine that works on any platform,
    /// including Embedded Swift and platforms without Foundation.
    ///
    /// - Parameters:
    ///   - data: The object instance to evaluate the predicate against.
    ///   - functions: Custom functions (keyed by name) that `.function` expressions can invoke.
    /// - Returns: Whether the object satisfies the predicate.
    ///
    /// - Note: The `.matches` operator requires regular expression support and always
    ///   evaluates to `false` on platforms without the full Foundation module.
    ///   The `.between` operator is not representable with a single expression value
    ///   and always evaluates to `false`.
    func evaluate(
        with data: ModelData,
        functions: [String: DatabaseFunction] = [:]
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

// MARK: - Supporting Types

/// A resolved predicate expression value — either an attribute or a relationship.
internal enum PredicateValue: Equatable, Hashable, Sendable {

    case attribute(AttributeValue)
    case relationship(RelationshipValue)
}

internal extension PredicateValue {

    /// Whether this value represents null.
    var isNull: Bool {
        switch self {
        case .attribute(.null), .relationship(.null):
            return true
        default:
            return false
        }
    }

    /// The underlying attribute value, if any.
    var attributeValue: AttributeValue? {
        guard case let .attribute(value) = self else { return nil }
        return value
    }

    /// An object identifier this value can represent, for relationship comparisons.
    var objectIDValue: ObjectID? {
        switch self {
        case let .relationship(.toOne(objectID)):
            return objectID
        case let .attribute(.string(rawValue)):
            return ObjectID(rawValue: rawValue)
        case let .attribute(.uuid(uuid)):
            return ObjectID(rawValue: uuid.uuidString)
        default:
            return nil
        }
    }
}

// MARK: - Expression Evaluation

internal extension FetchRequest.Predicate.Expression {

    /// Resolve this expression to a value for the given object.
    func evaluate(
        with data: ModelData,
        functions: [String: DatabaseFunction]
    ) -> PredicateValue? {
        switch self {
        case let .attribute(value):
            return .attribute(value)
        case let .relationship(value):
            return .relationship(value)
        case let .keyPath(keyPath):
            let key = PropertyKey(rawValue: keyPath.rawValue)
            if let attribute = data.attributes[key] {
                return .attribute(attribute)
            }
            if let relationship = data.relationships[key] {
                return .relationship(relationship)
            }
            return nil
        case let .function(function):
            guard let registered = functions[function.name] else {
                return nil
            }
            let arguments = function.arguments.map {
                $0.evaluate(with: data, functions: functions)?.attributeValue
            }
            return registered.evaluate(arguments).map { .attribute($0) }
        }
    }
}

// MARK: - Comparison Evaluation

internal extension FetchRequest.Predicate.Comparison {

    func evaluate(
        with data: ModelData,
        functions: [String: DatabaseFunction]
    ) -> Bool {
        let lhs = left.evaluate(with: data, functions: functions)
        let rhs = right.evaluate(with: data, functions: functions)
        // aggregate modifiers apply the comparison to each element of a to-many relationship
        if let modifier, case let .relationship(.toMany(objectIDs)) = lhs {
            switch modifier {
            case .any:
                return objectIDs.contains {
                    type.evaluate(.relationship(.toOne($0)), rhs, options: options)
                }
            case .all:
                return objectIDs.allSatisfy {
                    type.evaluate(.relationship(.toOne($0)), rhs, options: options)
                }
            }
        }
        return type.evaluate(lhs, rhs, options: options)
    }
}

// MARK: - Operator Evaluation

internal extension FetchRequest.Predicate.Comparison.Operator {

    func evaluate(
        _ lhs: PredicateValue?,
        _ rhs: PredicateValue?,
        options: Set<FetchRequest.Predicate.Comparison.Option>
    ) -> Bool {
        let caseInsensitive = options.contains(.caseInsensitive)
        switch self {
        case .equalTo:
            return PredicateValue.areEqual(lhs, rhs, caseInsensitive: caseInsensitive)
        case .notEqualTo:
            return PredicateValue.areEqual(lhs, rhs, caseInsensitive: caseInsensitive) == false
        case .lessThan:
            return AttributeValue.order(lhs?.attributeValue, rhs?.attributeValue).map { $0 < 0 } ?? false
        case .lessThanOrEqualTo:
            return AttributeValue.order(lhs?.attributeValue, rhs?.attributeValue).map { $0 <= 0 } ?? false
        case .greaterThan:
            return AttributeValue.order(lhs?.attributeValue, rhs?.attributeValue).map { $0 > 0 } ?? false
        case .greaterThanOrEqualTo:
            return AttributeValue.order(lhs?.attributeValue, rhs?.attributeValue).map { $0 >= 0 } ?? false
        case .beginsWith:
            return AttributeValue.stringCompare(lhs?.attributeValue, rhs?.attributeValue, caseInsensitive: caseInsensitive) { $0.hasPrefix($1) }
        case .endsWith:
            return AttributeValue.stringCompare(lhs?.attributeValue, rhs?.attributeValue, caseInsensitive: caseInsensitive) { $0.hasSuffix($1) }
        case .contains:
            // a to-many relationship contains an object identifier
            if case let .relationship(.toMany(objectIDs)) = lhs {
                guard let objectID = rhs?.objectIDValue else { return false }
                return objectIDs.contains(objectID)
            }
            return AttributeValue.stringCompare(lhs?.attributeValue, rhs?.attributeValue, caseInsensitive: caseInsensitive) { $0.contains($1) }
        case .in:
            // an object identifier is in a to-many relationship
            if case let .relationship(.toMany(objectIDs)) = rhs {
                guard let objectID = lhs?.objectIDValue else { return false }
                return objectIDs.contains(objectID)
            }
            // for strings, whether the left hand side is a substring of the right hand side
            return AttributeValue.stringCompare(lhs?.attributeValue, rhs?.attributeValue, caseInsensitive: caseInsensitive) { $1.contains($0) }
        case .like:
            return AttributeValue.stringCompare(lhs?.attributeValue, rhs?.attributeValue, caseInsensitive: caseInsensitive) { String.wildcardMatch($0, pattern: $1) }
        case .matches:
            #if canImport(Foundation) && !os(Android) && !hasFeature(Embedded)
            return AttributeValue.stringCompare(lhs?.attributeValue, rhs?.attributeValue, caseInsensitive: false) {
                $0.matches($1, options, nil)
            }
            #else
            // regular expressions require the full Foundation module
            return false
            #endif
        case .between:
            // the right hand side bounds aren't representable as a single expression value
            return false
        }
    }
}

// MARK: - Value Comparison

internal extension PredicateValue {

    static func areEqual(
        _ lhs: PredicateValue?,
        _ rhs: PredicateValue?,
        caseInsensitive: Bool
    ) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case let (.some(value), .none), let (.none, .some(value)):
            return value.isNull
        case let (.some(left), .some(right)):
            if left.isNull || right.isNull {
                return left.isNull && right.isNull
            }
            switch (left, right) {
            case let (.attribute(leftValue), .attribute(rightValue)):
                return AttributeValue.areEqual(leftValue, rightValue, caseInsensitive: caseInsensitive)
            case let (.relationship(leftValue), .relationship(rightValue)):
                if case let (.toOne(leftID), .toOne(rightID)) = (leftValue, rightValue) {
                    return leftID == rightID
                }
                return leftValue == rightValue
            default:
                // a to-one relationship can be compared against an identifier value
                if let leftID = left.objectIDValue, let rightID = right.objectIDValue {
                    return leftID == rightID
                }
                return false
            }
        }
    }
}

internal extension AttributeValue {

    /// A numeric representation for comparable value types, for ordering comparisons.
    var comparableDouble: Double? {
        switch self {
        case let .bool(value):      return value ? 1 : 0
        case let .int16(value):     return Double(value)
        case let .int32(value):     return Double(value)
        case let .int64(value):     return Double(value)
        case let .float(value):     return Double(value)
        case let .double(value):    return value
        case let .decimal(value):   return Double(value.description)
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
            if caseInsensitive, let leftString = left.stringValue, let rightString = right.stringValue {
                return leftString.lowercased() == rightString.lowercased()
            }
            if left == right {
                return true
            }
            // numeric values compare across integer and floating point types
            if let leftNumber = left.comparableDouble, let rightNumber = right.comparableDouble {
                return leftNumber == rightNumber
            }
            return false
        default:
            return false
        }
    }

    /// Ordering of two values: negative if `lhs < rhs`, zero if equal, positive if greater;
    /// `nil` if the values aren't order-comparable.
    static func order(_ lhs: AttributeValue?, _ rhs: AttributeValue?) -> Int? {
        guard let lhs, let rhs else { return nil }
        if let leftNumber = lhs.comparableDouble, let rightNumber = rhs.comparableDouble {
            if leftNumber < rightNumber { return -1 }
            if leftNumber > rightNumber { return 1 }
            return 0
        }
        if let leftString = lhs.stringValue, let rightString = rhs.stringValue {
            if leftString < rightString { return -1 }
            if leftString > rightString { return 1 }
            return 0
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

// MARK: - Wildcard Matching

internal extension String {

    /// Match a Cocoa-style `LIKE` pattern where `*` matches zero or more characters
    /// and `?` matches exactly one character. Pure Swift, works on all platforms.
    static func wildcardMatch(_ value: String, pattern: String) -> Bool {
        let value = Array(value)
        let pattern = Array(pattern)
        var valueIndex = 0
        var patternIndex = 0
        var starIndex: Int? = nil
        var starMatchIndex = 0
        while valueIndex < value.count {
            if patternIndex < pattern.count,
               pattern[patternIndex] == "?" || pattern[patternIndex] == value[valueIndex] {
                valueIndex += 1
                patternIndex += 1
            } else if patternIndex < pattern.count, pattern[patternIndex] == "*" {
                starIndex = patternIndex
                starMatchIndex = valueIndex
                patternIndex += 1
            } else if let lastStar = starIndex {
                // backtrack: let the last `*` consume one more character
                patternIndex = lastStar + 1
                starMatchIndex += 1
                valueIndex = starMatchIndex
            } else {
                return false
            }
        }
        while patternIndex < pattern.count, pattern[patternIndex] == "*" {
            patternIndex += 1
        }
        return patternIndex == pattern.count
    }
}
