//
//  ValueType.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/23/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

public enum ValueType {
    
    case Attribute(AttributeType)
    case Relationship(RelationshipType)
}

public enum AttributeType: Equatable {
    
    /// Attribute is a string.
    case String
    
    /// Attribute is a number.
    case Number(NumberType)
    
    /// Attribute is binary data.
    case Data
    
    /// Attribute is a date.
    case Date
    
    /// Attribute is transformable
    case Transformable
}

public func == (lhs: AttributeType, rhs: AttributeType) -> Bool {
    
    switch lhs {
        
    case .String: switch rhs { case .String: return true; default: return false }
    case .Data: switch rhs { case .Data: return true; default: return false }
    case .Date: switch rhs { case .Date: return true; default: return false }
    case .Transformable: switch rhs { case .Transformable: return true; default: return false }
    case .Number(let number):
        
        switch rhs {
            
        case .Number(let rhsNumber): return (number == rhsNumber)
        
        default: return false
        
        }
    }
}

/// Number attribute type.
public enum NumberType: String {
    
    /// Boolean number type.
    case Boolean
    
    /// Integer number type.
    case Integer
    
    /// Floating point number type.
    case Float
    
    /// Floating point number type.
    case Double
}

// Type of relationship
public enum RelationshipType: String {
    
    case ToOne
    case ToMany
    
    public init(toMany: Bool) {
        
        if toMany {
            
            self = .ToMany
        }
        else {
            
            self = .ToOne
        }
    }
    
    public var toMany: Bool {
        
        switch self {
            
        case .ToMany: return true
        case .ToOne: return false
        }
    }
}
