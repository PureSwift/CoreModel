//
//  Expression.swift
//  Predicate
//
//  Created by Alsey Coleman Miller on 4/2/17.
//  Copyright © 2017 PureSwift. All rights reserved.
//

/// Used to represent expressions in a predicate.
public enum Expression: Equatable, Hashable, Sendable {
    
    /// Expression that represents a given constant attribute value.
    case attribute(AttributeValue)
    
    /// Expression that represents a given constant attribute value.
    case relationship(RelationshipValue)
    
    /// Expression that invokes `value​For​Key​Path:​` with a given key path.
    case keyPath(PredicateKeyPath)
}

/// Type of predicate expression.
public enum ExpressionType: String, Codable, Sendable {
    
    case attribute
    case relationship
    case keyPath
}

public extension Expression {
    
    var type: ExpressionType {
        switch self {
        case .attribute: return .attribute
        case .relationship: return .relationship
        case .keyPath: return .keyPath
        }
    }
}

// MARK: - CustomStringConvertible

extension Expression: CustomStringConvertible {
    
    public var description: String {
        
        switch self {
        case let .attribute(value):     return value.predicateDescription
        case let .relationship(value):  return value.predicateDescription
        case let .keyPath(value):       return value.description
        }
    }
}

internal extension AttributeValue {
    
    var predicateDescription: String {
        
        switch self {
        case .null:                 return "nil"
        case let .string(value):    return "\"\(value)\""
        case let .data(value):      return value.description
        case let .date(value):      return value.description
        case let .uuid(value):      return value.uuidString
        case let .bool(value):      return value.description
        case let .int16(value):     return value.description
        case let .int32(value):     return value.description
        case let .int64(value):     return value.description
        case let .float(value):     return value.description
        case let .double(value):    return value.description
        case let .url(value):       return value.description
        case let .decimal(value):   return value.description
        }
    }
}

internal extension RelationshipValue {
    
    var predicateDescription: String {
        
        switch self {
        case .null:
            return "nil"
        case let .toOne(objectID):
            return objectID.rawValue
        case let .toMany(objectIDs):
            return "{" + objectIDs.reduce("", { $0 + ($0.isEmpty ? "" : ", ") + $1.rawValue }) + "}"
        }
    }
}

// MARK: - Codable

extension Expression: Codable {
    
    internal enum CodingKeys: String, CodingKey {
        
        case type
        case expression
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ExpressionType.self, forKey: .type)
        
        switch type {
        case .attribute:
            let expression = try container.decode(AttributeValue.self, forKey: .expression)
            self = .attribute(expression)
        case .relationship:
            let expression = try container.decode(RelationshipValue.self, forKey: .expression)
            self = .relationship(expression)
        case .keyPath:
            let keyPath = try container.decode(String.self, forKey: .expression)
            self = .keyPath(PredicateKeyPath(rawValue: keyPath))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        
        switch self {
        case let .attribute(value):
            try container.encode(value, forKey: .expression)
        case let .relationship(value):
            try container.encode(value, forKey: .expression)
        case let .keyPath(keyPath):
            try container.encode(keyPath.rawValue, forKey: .expression)
        }
    }
}

// MARK: - Extensions

public extension Expression {
    
    func compare(_ type: FetchRequest.Predicate.Comparison.Operator, _ rhs: Expression) -> FetchRequest.Predicate {
        
        let comparison = FetchRequest.Predicate.Comparison(left: self, right: rhs, type: type)
        return .comparison(comparison)
    }
    
    func compare(_ type: FetchRequest.Predicate.Comparison.Operator, _ options: Set<FetchRequest.Predicate.Comparison.Option>, _ rhs: Expression) -> FetchRequest.Predicate {
        
        let comparison = FetchRequest.Predicate.Comparison(left: self, right: rhs, type: type, options: options)
        return .comparison(comparison)
    }
    
    func compare(_ modifier: FetchRequest.Predicate.Comparison.Modifier, _ type: FetchRequest.Predicate.Comparison.Operator, _ options: Set<FetchRequest.Predicate.Comparison.Option>, _ rhs: Expression) -> FetchRequest.Predicate {
        
        let comparison = FetchRequest.Predicate.Comparison(left: self, right: rhs, type: type, modifier: modifier, options: options)
        return .comparison(comparison)
    }
}
