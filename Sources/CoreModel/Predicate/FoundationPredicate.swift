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
    /// CoreModel equivalent (e.g. subscripts, type casts, nested closures).
    init<T>(_ predicate: FoundationEssentials.Predicate<T>) throws {
        var context = PredicateConversionContext()
        context.variables[predicate.variable.key] = PredicateKeyPath(keys: [])
        self = try Self.predicate(converting: predicate.expression, in: context)
    }
    #else
    /// Creates a ``FetchRequest.Predicate`` from a ``Foundation.Predicate`` built with the `#Predicate` macro.
    ///
    /// Throws ``FetchRequest/Predicate/ConversionError`` for expressions with no
    /// CoreModel equivalent (e.g. subscripts, type casts, nested closures).
    init<T>(_ predicate: Foundation.Predicate<T>) throws {
        var context = PredicateConversionContext()
        context.variables[predicate.variable.key] = PredicateKeyPath(keys: [])
        self = try Self.predicate(converting: predicate.expression, in: context)
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

    /// A value expression (key path, constant, or arithmetic).
    case expression(FetchRequest.Predicate.Expression)

    /// A boolean predicate.
    case predicate(FetchRequest.Predicate)
}

/// State threaded through a conversion — the key path each predicate variable
/// (the root input, or a collection element bound by `allSatisfy`/`contains(where:)`)
/// resolves to.
@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
internal struct PredicateConversionContext {

    var variables = [PredicateExpressions.VariableID: PredicateKeyPath]()
}

/// Conforming `PredicateExpressions` node types convert themselves to CoreModel form.
@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
internal protocol CoreModelPredicateConvertible {

    func toCoreModel(in context: PredicateConversionContext) throws -> ConvertedPredicateExpression
}

/// Range nodes convert to bounds for a compound comparison predicate.
@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
internal protocol CoreModelRangeConvertible {

    func coreModelBounds(in context: PredicateConversionContext) throws -> (
        lower: FetchRequest.Predicate.Expression,
        upper: FetchRequest.Predicate.Expression,
        upperOperator: FetchRequest.Predicate.Comparison.Operator
    )
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
internal extension FetchRequest.Predicate {

    static func node(converting expression: Any, in context: PredicateConversionContext) throws -> ConvertedPredicateExpression {
        guard let convertible = expression as? any CoreModelPredicateConvertible else {
            throw ConversionError.unsupportedExpression(String(describing: Swift.type(of: expression)))
        }
        return try convertible.toCoreModel(in: context)
    }

    static func predicate(converting expression: Any, in context: PredicateConversionContext) throws -> FetchRequest.Predicate {
        switch try node(converting: expression, in: context) {
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

    static func expression(converting expression: Any, in context: PredicateConversionContext) throws -> Expression {
        switch try node(converting: expression, in: context) {
        case let .expression(expression):
            return expression
        case let .predicate(predicate):
            throw ConversionError.unsupportedExpression(predicate.description)
        }
    }

    /// Convert the sequence operand of a collection expression to a key path.
    static func keyPath(converting expression: Any, in context: PredicateConversionContext) throws -> PredicateKeyPath {
        guard case let .expression(.keyPath(keyPath)) = try node(converting: expression, in: context) else {
            throw ConversionError.unsupportedExpression(String(describing: Swift.type(of: expression)))
        }
        return keyPath
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

    /// Convert a bound-variable test into a comparison with the given modifier
    /// (`ALL` for `allSatisfy`, `ANY` for `contains(where:)`).
    static func modifiedComparison(
        sequence: Any,
        test: Any,
        variable: PredicateExpressions.VariableID,
        modifier: Comparison.Modifier,
        in context: PredicateConversionContext
    ) throws -> ConvertedPredicateExpression {
        let base = try keyPath(converting: sequence, in: context)
        var innerContext = context
        innerContext.variables[variable] = base
        let test = try predicate(converting: test, in: innerContext)
        // only a single direct comparison can carry an ALL/ANY modifier
        guard case var .comparison(comparison) = test, comparison.modifier == nil else {
            throw ConversionError.unsupportedExpression(test.description)
        }
        comparison.modifier = modifier
        return .predicate(.comparison(comparison))
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

    func toCoreModel(in context: PredicateConversionContext) throws -> ConvertedPredicateExpression {
        // the fetched object or a bound collection element; key paths are appended by `KeyPath` nodes
        guard let keyPath = context.variables[key] else {
            throw FetchRequest.Predicate.ConversionError.unsupportedExpression(String(describing: Swift.type(of: self)))
        }
        return .expression(.keyPath(keyPath))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.KeyPath: CoreModelPredicateConvertible {

    func toCoreModel(in context: PredicateConversionContext) throws -> ConvertedPredicateExpression {
        let base = try FetchRequest.Predicate.keyPath(converting: root, in: context)
        let names = try PredicateKeyPath.propertyNames(for: keyPath as AnyKeyPath)
        let keys = base.keys + names.map { .property($0) }
        return .expression(.keyPath(PredicateKeyPath(keys: keys)))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.Value: CoreModelPredicateConvertible {

    func toCoreModel(in context: PredicateConversionContext) throws -> ConvertedPredicateExpression {
        // the macro wraps regexes in a type that retains the source pattern
        if #available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, *),
            let regex = value as? PredicateExpressions.PredicateRegex {
            return .expression(.attribute(.string(regex.stringRepresentation)))
        }
        guard let encodable = value as? AttributeEncodable else {
            throw FetchRequest.Predicate.ConversionError.unsupportedValue(String(describing: Swift.type(of: value)))
        }
        return .expression(.attribute(encodable.attributeValue))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.NilLiteral: CoreModelPredicateConvertible {

    func toCoreModel(in context: PredicateConversionContext) throws -> ConvertedPredicateExpression {
        .expression(.attribute(.null))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.Equal: CoreModelPredicateConvertible {

    func toCoreModel(in context: PredicateConversionContext) throws -> ConvertedPredicateExpression {
        .predicate(.comparison(.init(
            left: try FetchRequest.Predicate.expression(converting: lhs, in: context),
            right: try FetchRequest.Predicate.expression(converting: rhs, in: context),
            type: .equalTo
        )))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.NotEqual: CoreModelPredicateConvertible {

    func toCoreModel(in context: PredicateConversionContext) throws -> ConvertedPredicateExpression {
        .predicate(.comparison(.init(
            left: try FetchRequest.Predicate.expression(converting: lhs, in: context),
            right: try FetchRequest.Predicate.expression(converting: rhs, in: context),
            type: .notEqualTo
        )))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.Comparison: CoreModelPredicateConvertible {

    func toCoreModel(in context: PredicateConversionContext) throws -> ConvertedPredicateExpression {
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
            left: try FetchRequest.Predicate.expression(converting: lhs, in: context),
            right: try FetchRequest.Predicate.expression(converting: rhs, in: context),
            type: type
        )))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.Conjunction: CoreModelPredicateConvertible {

    func toCoreModel(in context: PredicateConversionContext) throws -> ConvertedPredicateExpression {
        let lhs = try FetchRequest.Predicate.predicate(converting: self.lhs, in: context)
        let rhs = try FetchRequest.Predicate.predicate(converting: self.rhs, in: context)
        return .predicate(.compound(.and(
            FetchRequest.Predicate.subpredicates(of: lhs, .and)
                + FetchRequest.Predicate.subpredicates(of: rhs, .and)
        )))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.Disjunction: CoreModelPredicateConvertible {

    func toCoreModel(in context: PredicateConversionContext) throws -> ConvertedPredicateExpression {
        let lhs = try FetchRequest.Predicate.predicate(converting: self.lhs, in: context)
        let rhs = try FetchRequest.Predicate.predicate(converting: self.rhs, in: context)
        return .predicate(.compound(.or(
            FetchRequest.Predicate.subpredicates(of: lhs, .or)
                + FetchRequest.Predicate.subpredicates(of: rhs, .or)
        )))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.Negation: CoreModelPredicateConvertible {

    func toCoreModel(in context: PredicateConversionContext) throws -> ConvertedPredicateExpression {
        .predicate(.compound(.not(try FetchRequest.Predicate.predicate(converting: wrapped, in: context))))
    }
}

// MARK: - Arithmetic Conformances

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.Arithmetic: CoreModelPredicateConvertible {

    func toCoreModel(in context: PredicateConversionContext) throws -> ConvertedPredicateExpression {
        let function: FetchRequest.Predicate.ArithmeticExpression.Function
        switch op {
        case .add:
            function = .add
        case .subtract:
            function = .subtract
        case .multiply:
            function = .multiply
        @unknown default:
            throw FetchRequest.Predicate.ConversionError.unsupportedExpression(String(describing: op))
        }
        return .expression(.arithmetic(.init(
            function: function,
            left: try FetchRequest.Predicate.expression(converting: lhs, in: context),
            right: try FetchRequest.Predicate.expression(converting: rhs, in: context)
        )))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.FloatDivision: CoreModelPredicateConvertible {

    func toCoreModel(in context: PredicateConversionContext) throws -> ConvertedPredicateExpression {
        .expression(.arithmetic(.init(
            function: .divide,
            left: try FetchRequest.Predicate.expression(converting: lhs, in: context),
            right: try FetchRequest.Predicate.expression(converting: rhs, in: context)
        )))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.IntDivision: CoreModelPredicateConvertible {

    func toCoreModel(in context: PredicateConversionContext) throws -> ConvertedPredicateExpression {
        .expression(.arithmetic(.init(
            function: .divide,
            left: try FetchRequest.Predicate.expression(converting: lhs, in: context),
            right: try FetchRequest.Predicate.expression(converting: rhs, in: context)
        )))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.IntRemainder: CoreModelPredicateConvertible {

    func toCoreModel(in context: PredicateConversionContext) throws -> ConvertedPredicateExpression {
        .expression(.arithmetic(.init(
            function: .modulus,
            left: try FetchRequest.Predicate.expression(converting: lhs, in: context),
            right: try FetchRequest.Predicate.expression(converting: rhs, in: context)
        )))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.UnaryMinus: CoreModelPredicateConvertible {

    func toCoreModel(in context: PredicateConversionContext) throws -> ConvertedPredicateExpression {
        // NSExpression has no negation function, so multiply by -1
        .expression(.arithmetic(.init(
            function: .multiply,
            left: try FetchRequest.Predicate.expression(converting: wrapped, in: context),
            right: .attribute(.int64(-1))
        )))
    }
}

// MARK: - Collection Conformances

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.SequenceContains: CoreModelPredicateConvertible {

    func toCoreModel(in context: PredicateConversionContext) throws -> ConvertedPredicateExpression {
        .predicate(.comparison(.init(
            left: try FetchRequest.Predicate.expression(converting: sequence, in: context),
            right: try FetchRequest.Predicate.expression(converting: element, in: context),
            type: .contains
        )))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.CollectionContainsCollection: CoreModelPredicateConvertible {

    func toCoreModel(in context: PredicateConversionContext) throws -> ConvertedPredicateExpression {
        .predicate(.comparison(.init(
            left: try FetchRequest.Predicate.expression(converting: base, in: context),
            right: try FetchRequest.Predicate.expression(converting: other, in: context),
            type: .contains
        )))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.SequenceStartsWith: CoreModelPredicateConvertible {

    func toCoreModel(in context: PredicateConversionContext) throws -> ConvertedPredicateExpression {
        .predicate(.comparison(.init(
            left: try FetchRequest.Predicate.expression(converting: base, in: context),
            right: try FetchRequest.Predicate.expression(converting: prefix, in: context),
            type: .beginsWith
        )))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.SequenceAllSatisfy: CoreModelPredicateConvertible {

    func toCoreModel(in context: PredicateConversionContext) throws -> ConvertedPredicateExpression {
        try FetchRequest.Predicate.modifiedComparison(
            sequence: sequence,
            test: test,
            variable: variable.key,
            modifier: .all,
            in: context
        )
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.SequenceContainsWhere: CoreModelPredicateConvertible {

    func toCoreModel(in context: PredicateConversionContext) throws -> ConvertedPredicateExpression {
        try FetchRequest.Predicate.modifiedComparison(
            sequence: sequence,
            test: test,
            variable: variable.key,
            modifier: .any,
            in: context
        )
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.SequenceMinimum: CoreModelPredicateConvertible {

    func toCoreModel(in context: PredicateConversionContext) throws -> ConvertedPredicateExpression {
        let base = try FetchRequest.Predicate.keyPath(converting: elements, in: context)
        return .expression(.keyPath(PredicateKeyPath(keys: base.keys + [.operator(.min)])))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.SequenceMaximum: CoreModelPredicateConvertible {

    func toCoreModel(in context: PredicateConversionContext) throws -> ConvertedPredicateExpression {
        let base = try FetchRequest.Predicate.keyPath(converting: elements, in: context)
        return .expression(.keyPath(PredicateKeyPath(keys: base.keys + [.operator(.max)])))
    }
}

// MARK: - Range Conformances

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.RangeExpressionContains: CoreModelPredicateConvertible {

    func toCoreModel(in context: PredicateConversionContext) throws -> ConvertedPredicateExpression {
        guard let range = self.range as? any CoreModelRangeConvertible else {
            throw FetchRequest.Predicate.ConversionError.unsupportedExpression(String(describing: Swift.type(of: self.range)))
        }
        let bounds = try range.coreModelBounds(in: context)
        let element = try FetchRequest.Predicate.expression(converting: self.element, in: context)
        // CoreModel can't evaluate BETWEEN, so lower ranges to a compound comparison
        return .predicate(.compound(.and([
            .comparison(.init(left: element, right: bounds.lower, type: .greaterThanOrEqualTo)),
            .comparison(.init(left: element, right: bounds.upper, type: bounds.upperOperator))
        ])))
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.ClosedRange: CoreModelRangeConvertible {

    func coreModelBounds(in context: PredicateConversionContext) throws -> (
        lower: FetchRequest.Predicate.Expression,
        upper: FetchRequest.Predicate.Expression,
        upperOperator: FetchRequest.Predicate.Comparison.Operator
    ) {
        (
            lower: try FetchRequest.Predicate.expression(converting: self.lower, in: context),
            upper: try FetchRequest.Predicate.expression(converting: self.upper, in: context),
            upperOperator: .lessThanOrEqualTo
        )
    }
}

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.Range: CoreModelRangeConvertible {

    func coreModelBounds(in context: PredicateConversionContext) throws -> (
        lower: FetchRequest.Predicate.Expression,
        upper: FetchRequest.Predicate.Expression,
        upperOperator: FetchRequest.Predicate.Comparison.Operator
    ) {
        (
            lower: try FetchRequest.Predicate.expression(converting: self.lower, in: context),
            upper: try FetchRequest.Predicate.expression(converting: self.upper, in: context),
            upperOperator: .lessThan
        )
    }
}

// MARK: - String Conformances

@available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, *)
extension PredicateExpressions.StringContainsRegex: CoreModelPredicateConvertible {

    func toCoreModel(in context: PredicateConversionContext) throws -> ConvertedPredicateExpression {
        let subject = try FetchRequest.Predicate.expression(converting: self.subject, in: context)
        let pattern = try FetchRequest.Predicate.expression(converting: self.regex, in: context)
        guard case let .attribute(.string(pattern)) = pattern else {
            throw FetchRequest.Predicate.ConversionError.unsupportedValue(pattern.description)
        }
        // `MATCHES` matches the whole value, so pad the pattern to express `contains`
        return .predicate(.comparison(.init(
            left: subject,
            right: .attribute(.string(".*" + pattern + ".*")),
            type: .matches
        )))
    }
}

#if canImport(Darwin)
@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension PredicateExpressions.StringLocalizedStandardContains: CoreModelPredicateConvertible {

    func toCoreModel(in context: PredicateConversionContext) throws -> ConvertedPredicateExpression {
        .predicate(.comparison(.init(
            left: try FetchRequest.Predicate.expression(converting: root, in: context),
            right: try FetchRequest.Predicate.expression(converting: other, in: context),
            type: .contains,
            options: [.caseInsensitive, .diacriticInsensitive]
        )))
    }
}
#endif

#endif
