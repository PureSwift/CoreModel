//
//  ArithmeticExpression.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 8/16/26.
//  Copyright © 2026 PureSwift. All rights reserved.
//

public extension FetchRequest.Predicate {

    /// An arithmetic operation on two expressions (e.g. `age + 1`).
    struct ArithmeticExpression: Equatable, Hashable, Sendable {

        /// The arithmetic function to apply.
        public var function: Function

        /// The left operand.
        public var left: Expression

        /// The right operand.
        public var right: Expression

        public init(function: Function, left: Expression, right: Expression) {
            self.function = function
            self.left = left
            self.right = right
        }
    }
}

// MARK: - Supporting Types

public extension FetchRequest.Predicate.ArithmeticExpression {

    /// Arithmetic function.
    ///
    /// Raw values match the corresponding `NSExpression` function names,
    /// with operands passed in `(left, right)` order.
    enum Function: String, Sendable, CaseIterable {

        /// Addition (`left + right`).
        case add        = "add:to:"

        /// Subtraction (`left - right`).
        case subtract   = "from:subtract:"

        /// Multiplication (`left * right`).
        case multiply   = "multiply:by:"

        /// Division (`left / right`), always producing a floating-point value.
        case divide     = "divide:by:"

        /// Remainder (`left % right`), integers only.
        case modulus    = "modulus:by:"
    }
}

public extension FetchRequest.Predicate.ArithmeticExpression.Function {

    /// The operator symbol (e.g. `+`).
    var symbol: String {
        switch self {
        case .add:      return "+"
        case .subtract: return "-"
        case .multiply: return "*"
        case .divide:   return "/"
        case .modulus:  return "%"
        }
    }
}

// MARK: - CustomStringConvertible

extension FetchRequest.Predicate.ArithmeticExpression: CustomStringConvertible {

    public var description: String {
        "(" + left.description + " " + function.symbol + " " + right.description + ")"
    }
}

// MARK: - Codable

#if !hasFeature(Embedded)
extension FetchRequest.Predicate.ArithmeticExpression: Codable {}
extension FetchRequest.Predicate.ArithmeticExpression.Function: Codable {}
#endif
