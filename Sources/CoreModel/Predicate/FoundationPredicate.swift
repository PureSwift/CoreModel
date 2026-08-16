//
//  FoundationPredicate.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 8/16/26.
//  Copyright © 2026 PureSwift. All rights reserved.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

#if canImport(FoundationEssentials) || canImport(Foundation)

// MARK: - Foundation.Predicate Conversion

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
public extension FetchRequest.Predicate {

    #if canImport(FoundationEssentials)
    /// Creates a ``FetchRequest.Predicate`` from a `Predicate` built with the `#Predicate` macro.
    ///
    /// Throws ``FetchRequest/Predicate/ConversionError`` for expressions with no
    /// CoreModel equivalent (e.g. arithmetic, subscripts, closures).
    init<T>(_ predicate: FoundationEssentials.Predicate<T>) throws {
        self = try Self.predicate(converting: predicate.expression)
    }
    #else
    /// Creates a ``FetchRequest.Predicate`` from a ``Foundation.Predicate`` built with the `#Predicate` macro.
    ///
    /// Throws ``FetchRequest/Predicate/ConversionError`` for expressions with no
    /// CoreModel equivalent (e.g. arithmetic, subscripts, closures).
    init<T>(_ predicate: Foundation.Predicate<T>) throws {
        self = try Self.predicate(converting: predicate.expression)
    }
    #endif
}

// MARK: - Conversion Error

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
public extension FetchRequest.Predicate {

    /// An error converting a ``Foundation.Predicate`` expression tree.
    enum ConversionError: Swift.Error, Sendable {

        /// The expression type has no CoreModel equivalent.
        case unsupportedExpression(String)

        /// The key path doesn't reference stored properties by name.
        case unsupportedKeyPath(String)

        /// The constant value can't be represented as an attribute value.
        case unsupportedValue(String)
    }
}

// MARK: - Conversion

/// Intermediate result of converting a `PredicateExpressions` tree node.
@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
internal enum ConvertedPredicateExpression {

    /// A value expression (key path or constant).
    case expression(FetchRequest.Predicate.Expression)

    /// A boolean predicate.
    case predicate(FetchRequest.Predicate)
}

/// Conforming `PredicateExpressions` node types convert themselves to CoreModel form.
@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
internal protocol CoreModelPredicateConvertible {

    func toCoreModel() throws -> ConvertedPredicateExpression
}

/// Range nodes convert to inclusive bounds for a compound `>= lower && <= upper` predicate.
@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
internal protocol CoreModelRangeConvertible {

    func coreModelBounds() throws -> (lower: FetchRequest.Predicate.Expression, upper: FetchRequest.Predicate.Expression)
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
internal extension FetchRequest.Predicate {

    static func node(converting expression: Any) throws -> ConvertedPredicateExpression {
        guard let convertible = expression as? any CoreModelPredicateConvertible else {
            throw ConversionError.unsupportedExpression(String(describing: Swift.type(of: expression)))
        }
        return try convertible.toCoreModel()
    }

    static func predicate(converting expression: Any) throws -> FetchRequest.Predicate {
        switch try node(converting: expression) {
        case let .predicate(predicate):
            return predicate
        case let .expression(.attribute(.bool(value))):
            return .value(value)
        case let .expression(.keyPath(keyPath)):
            // a boolean property used directly as a predicate
            return .comparison(.init(left: .keyPath(keyPath), right: .attribute(.bool(true))))
        case let .expression(expression):
            throw ConversionError.unsupportedExpression(expression.description)
        }
    }

    static func expression(converting expression: Any) throws -> Expression {
        switch try node(converting: expression) {
        case let .expression(expression):
            return expression
        case let .predicate(predicate):
            throw ConversionError.unsupportedExpression(predicate.description)
        }
    }

    /// Merge nested compounds of the same logical type (`a && b && c` becomes one `.and`).
    static func subpredicates(of predicate: FetchRequest.Predicate, _ type: Compound.Logical​Type) -> [FetchRequest.Predicate] {
        guard type != .not,
            case let .compound(compound) = predicate,
            compound.type == type else {
            return [predicate]
        }
        return compound.subpredicates
    }
}

// MARK: - Key Path Resolution

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
internal extension PredicateKeyPath {

    /// Resolve a Swift key path to its property names.
    ///
    /// Uses Key-Value Coding on Darwin (for `@objc` properties), falling back to
    /// parsing the key path's reflection-based `debugDescription` (e.g. `\Person.name`),
    /// which requires field metadata for the traversed stored properties.
    static func propertyNames(for keyPath: AnyKeyPath) throws -> [String] {
        #if canImport(Darwin)
        if let kvcString = keyPath._kvcKeyPathString {
            return kvcString.split(separator: ".").map(String.init)
        }
        #endif
        let description = keyPath.debugDescription
        guard description.hasPrefix("\\") else {
            throw FetchRequest.Predicate.ConversionError.unsupportedKeyPath(description)
        }
        let components = description.dropFirst().split(separator: ".").dropFirst()
        let names: [String] = components.map { component in
            // optional chaining and force unwrapping traverse the same property
            var name = Substring(component)
            while name.hasSuffix("?") || name.hasSuffix("!") {
                name = name.dropLast()
            }
            return String(name)
        }
        guard names.isEmpty == false,
            names.allSatisfy({ name in
                name.isEmpty == false
                    && name.contains("<") == false
                    && name.hasPrefix("subscript") == false
            }) else {
            throw FetchRequest.Predicate.ConversionError.unsupportedKeyPath(description)
        }
        return names
    }
}

// MARK: - PredicateExpressions Conformances

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.Variable: CoreModelPredicateConvertible {

    func toCoreModel() throws -> ConvertedPredicateExpression {
        // the fetched object itself; key paths are appended by `KeyPath` nodes
        .expression(.keyPath(PredicateKeyPath(keys: [])))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.KeyPath: CoreModelPredicateConvertible {

    func toCoreModel() throws -> ConvertedPredicateExpression {
        guard case let .expression(.keyPath(base)) = try FetchRequest.Predicate.node(converting: root) else {
            throw FetchRequest.Predicate.ConversionError.unsupportedKeyPath(String(describing: keyPath))
        }
        let names = try PredicateKeyPath.propertyNames(for: keyPath as AnyKeyPath)
        let keys = base.keys + names.map { .property($0) }
        return .expression(.keyPath(PredicateKeyPath(keys: keys)))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.Value: CoreModelPredicateConvertible {

    func toCoreModel() throws -> ConvertedPredicateExpression {
        guard let encodable = value as? AttributeEncodable else {
            throw FetchRequest.Predicate.ConversionError.unsupportedValue(String(describing: type(of: value)))
        }
        return .expression(.attribute(encodable.attributeValue))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.NilLiteral: CoreModelPredicateConvertible {

    func toCoreModel() throws -> ConvertedPredicateExpression {
        .expression(.attribute(.null))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.Equal: CoreModelPredicateConvertible {

    func toCoreModel() throws -> ConvertedPredicateExpression {
        .predicate(.comparison(.init(
            left: try FetchRequest.Predicate.expression(converting: lhs),
            right: try FetchRequest.Predicate.expression(converting: rhs),
            type: .equalTo
        )))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.NotEqual: CoreModelPredicateConvertible {

    func toCoreModel() throws -> ConvertedPredicateExpression {
        .predicate(.comparison(.init(
            left: try FetchRequest.Predicate.expression(converting: lhs),
            right: try FetchRequest.Predicate.expression(converting: rhs),
            type: .notEqualTo
        )))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.Comparison: CoreModelPredicateConvertible {

    func toCoreModel() throws -> ConvertedPredicateExpression {
        let type: FetchRequest.Predicate.Comparison.Operator
        switch op {
        case .lessThan:
            type = .lessThan
        case .lessThanOrEqual:
            type = .lessThanOrEqualTo
        case .greaterThan:
            type = .greaterThan
        case .greaterThanOrEqual:
            type = .greaterThanOrEqualTo
        @unknown default:
            throw FetchRequest.Predicate.ConversionError.unsupportedExpression(String(describing: op))
        }
        return .predicate(.comparison(.init(
            left: try FetchRequest.Predicate.expression(converting: lhs),
            right: try FetchRequest.Predicate.expression(converting: rhs),
            type: type
        )))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.Conjunction: CoreModelPredicateConvertible {

    func toCoreModel() throws -> ConvertedPredicateExpression {
        let lhs = try FetchRequest.Predicate.predicate(converting: self.lhs)
        let rhs = try FetchRequest.Predicate.predicate(converting: self.rhs)
        return .predicate(.compound(.and(
            FetchRequest.Predicate.subpredicates(of: lhs, .and)
                + FetchRequest.Predicate.subpredicates(of: rhs, .and)
        )))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.Disjunction: CoreModelPredicateConvertible {

    func toCoreModel() throws -> ConvertedPredicateExpression {
        let lhs = try FetchRequest.Predicate.predicate(converting: self.lhs)
        let rhs = try FetchRequest.Predicate.predicate(converting: self.rhs)
        return .predicate(.compound(.or(
            FetchRequest.Predicate.subpredicates(of: lhs, .or)
                + FetchRequest.Predicate.subpredicates(of: rhs, .or)
        )))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.Negation: CoreModelPredicateConvertible {

    func toCoreModel() throws -> ConvertedPredicateExpression {
        .predicate(.compound(.not(try FetchRequest.Predicate.predicate(converting: wrapped))))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.SequenceContains: CoreModelPredicateConvertible {

    func toCoreModel() throws -> ConvertedPredicateExpression {
        .predicate(.comparison(.init(
            left: try FetchRequest.Predicate.expression(converting: sequence),
            right: try FetchRequest.Predicate.expression(converting: element),
            type: .contains
        )))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.CollectionContainsCollection: CoreModelPredicateConvertible {

    func toCoreModel() throws -> ConvertedPredicateExpression {
        .predicate(.comparison(.init(
            left: try FetchRequest.Predicate.expression(converting: base),
            right: try FetchRequest.Predicate.expression(converting: other),
            type: .contains
        )))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.SequenceStartsWith: CoreModelPredicateConvertible {

    func toCoreModel() throws -> ConvertedPredicateExpression {
        .predicate(.comparison(.init(
            left: try FetchRequest.Predicate.expression(converting: base),
            right: try FetchRequest.Predicate.expression(converting: prefix),
            type: .beginsWith
        )))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.RangeExpressionContains: CoreModelPredicateConvertible {

    func toCoreModel() throws -> ConvertedPredicateExpression {
        guard let range = self.range as? any CoreModelRangeConvertible else {
            throw FetchRequest.Predicate.ConversionError.unsupportedExpression(String(describing: type(of: self.range)))
        }
        let bounds = try range.coreModelBounds()
        let element = try FetchRequest.Predicate.expression(converting: self.element)
        // CoreModel can't evaluate BETWEEN, so lower ranges to a compound comparison
        return .predicate(.compound(.and([
            .comparison(.init(left: element, right: bounds.lower, type: .greaterThanOrEqualTo)),
            .comparison(.init(left: element, right: bounds.upper, type: .lessThanOrEqualTo))
        ])))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.ClosedRange: CoreModelRangeConvertible {

    func coreModelBounds() throws -> (lower: FetchRequest.Predicate.Expression, upper: FetchRequest.Predicate.Expression) {
        (
            lower: try FetchRequest.Predicate.expression(converting: self.lower),
            upper: try FetchRequest.Predicate.expression(converting: self.upper)
        )
    }
}

#if canImport(Darwin)
@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.StringLocalizedStandardContains: CoreModelPredicateConvertible {

    func toCoreModel() throws -> ConvertedPredicateExpression {
        .predicate(.comparison(.init(
            left: try FetchRequest.Predicate.expression(converting: root),
            right: try FetchRequest.Predicate.expression(converting: other),
            type: .contains,
            options: [.caseInsensitive, .diacriticInsensitive]
        )))
    }
}
#endif

#endif
