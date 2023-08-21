//
//  Compound.swift
//  Predicate
//
//  Created by Alsey Coleman Miller on 4/2/17.
//  Copyright © 2017 PureSwift. All rights reserved.
//

public extension FetchRequest.Predicate {
    
    /// Predicate type used to represent logical “gate” operations (AND/OR/NOT) and comparison operations.
    indirect enum Compound: Equatable, Hashable, Sendable {
        
        case and([FetchRequest.Predicate])
        case or([FetchRequest.Predicate])
        case not(FetchRequest.Predicate)
    }
}

// MARK: - Accessors

public extension FetchRequest.Predicate.Compound {
    
    var type: Logical​Type {
        
        switch self {
        case .and:  return .and
        case .or:   return .or
        case .not:  return .not
        }
    }
    
    var subpredicates: [FetchRequest.Predicate] {
        
        switch self {
        case let .and(subpredicates):   return subpredicates
        case let .or(subpredicates):    return subpredicates
        case let .not(subpredicate):    return [subpredicate]
        }
    }
}

// MARK: - Supporting Types

public extension FetchRequest.Predicate.Compound {
    
    /// Possible Compund Predicate types.
    enum Logical​Type: String, Codable, Sendable {
        
        /// A logical NOT predicate.
        case not = "NOT"
        
        /// A logical AND predicate.
        case and = "AND"
        
        /// A logical OR predicate.
        case or = "OR"
    }
}

// MARK: - CustomStringConvertible

extension FetchRequest.Predicate.Compound: CustomStringConvertible {
    
    public var description: String {
        
        guard subpredicates.isEmpty == false else {
            return "(Empty \(type) predicate)"
        }
        
        var text = ""
        
        for (index, predicate) in subpredicates.enumerated() {
            
            let showType: Bool
            
            if index == 0 {
                showType = subpredicates.count == 1
            } else {
                showType = true
                text += " "
            }
            
            if showType {
                text += type.rawValue + " "
            }
            
            let includeBrackets: Bool
            
            switch predicate {
            case .compound:
                includeBrackets = true
            case .comparison,
                 .value:
                includeBrackets = false
            }
            
            text += includeBrackets ? "(" + predicate.description + ")" : predicate.description
        }
        
        return text
    }
}


// MARK: - Codable

extension FetchRequest.Predicate.Compound: Codable {
    
    internal enum CodingKeys: String, CodingKey {
        
        case type
        case predicates
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(FetchRequest.Predicate.Compound.Logical​Type.self, forKey: .type)
        
        switch type {
        case .and:
            let predicates = try container.decode([FetchRequest.Predicate].self, forKey: .predicates)
            self = .and(predicates)
        case .or:
            let predicates = try container.decode([FetchRequest.Predicate].self, forKey: .predicates)
            self = .or(predicates)
        case .not:
            let predicate = try container.decode(FetchRequest.Predicate.self, forKey: .predicates)
            self = .not(predicate)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        
        switch self {
        case let .and(predicates):
            try container.encode(predicates, forKey: .predicates)
        case let .or(predicates):
            try container.encode(predicates, forKey: .predicates)
        case let .not(predicate):
            try container.encode(predicate, forKey: .predicates)
        }
    }
}

// MARK: - Predicate Operators

public func && (lhs: FetchRequest.Predicate, rhs: FetchRequest.Predicate) -> FetchRequest.Predicate {
    return .compound(.and([lhs, rhs]))
}

public func && (lhs: FetchRequest.Predicate, rhs: [FetchRequest.Predicate]) -> FetchRequest.Predicate {
    return .compound(.and([lhs] + rhs))
}

public func || (lhs: FetchRequest.Predicate, rhs: FetchRequest.Predicate) -> FetchRequest.Predicate {
    return .compound(.or([lhs, rhs]))
}

public func || (lhs: FetchRequest.Predicate, rhs: [FetchRequest.Predicate]) -> FetchRequest.Predicate {
    return .compound(.or([lhs] + rhs))
}

public prefix func ! (rhs: FetchRequest.Predicate) -> FetchRequest.Predicate {
    return .compound(.not(rhs))
}
