//
//  Value.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/23/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import SwiftFoundation

public typealias ValuesObject = [String: Value]

public func ==(lhs: Value, rhs: Value) -> Bool {
    
    switch lhs {
        
    case .Null: switch rhs { case .Null: return true; default: return false }
        
    case let .Attribute(leftVal): switch rhs { case let .Attribute(rightVal): return leftVal == rightVal; default: return false }
        
    case let .Relationship(leftRel): switch rhs { case let .Relationship(rightRel): return leftRel == rightRel; default: return false }
        
    }
}

public enum Value: JSONEncodable, CustomDebugStringConvertible {
    
    case Null
    
    case Attribute(AttributeValue)
    
    case Relationship(RelationshipValue)
    
    public var rawValue: Any {
        
        switch self {
            
        case Null: return SwiftFoundation.Null()
        case let .Attribute(value): return value.rawValue
        case let .Relationship(value): return value.rawValue
        }
    }
    
    public var debugDescription: String {
        switch self {
        case Null: return "(null)"
        case let Attribute(value): return "A:\(value)"
        case let Relationship(value): return "R:\(value)"
        }
    }
}

public func ==(lhs: AttributeValue, rhs: AttributeValue) -> Bool {
    
    switch lhs {
        
    case .String(let leftString): switch rhs { case .String(let rightString): return leftString == rightString; default: return false }
    case .Data(let leftData): switch rhs { case .Data(let rightData): return leftData == rightData; default: return false }
    case .Date(let leftDate): switch rhs { case .Date(let rightDate): return leftDate == rightDate; default: return false }
    case .Transformable(let leftTrans):
        
        switch rhs {
        
        case .Transformable(let rightTrans): return leftTrans == rightTrans
        
        default: return false
            
        }
    case .Number(let number):
        
        switch rhs {
            
        case .Number(let rhsNumber): return (number == rhsNumber)
            
        default: return false
            
        }
    }

}

public enum AttributeValue: Equatable, CustomDebugStringConvertible {
    
    case String(StringValue)
    
    case Number(NumberValue)
    
    case Data(DataValue)
    
    case Date(DateValue)
    
    case Transformable(DataConvertible)
    
    public var rawValue: Any {
        
        switch self {
            
        case let .String(value):            return value
        case let .Data(value):              return value
        case let .Date(value):              return value
        case let .Number(value):            return value.rawValue
        case let .Transformable(value):     return value
        }
    }
    
    public var debugDescription: Swift.String {
        
        if let dd = rawValue as? CustomDebugStringConvertible {
            return dd.debugDescription
        }
        
        return "\(rawValue)"
    }
}

public func ==(lhs: NumberValue, rhs: NumberValue) -> Bool {
    
    switch lhs {
    case .Boolean(let lb): switch rhs { case .Boolean(let rb): return lb == rb; default: return false }
    case .Integer(let ll): switch rhs { case .Integer(let rl): return ll == rl; default: return false }
    case .Float(let lf): switch rhs { case .Float(let rf): return lf == rf; default: return false }
    case .Double(let ld): switch rhs { case .Double(let rd): return ld == rd; default: return false }
    }
}

public enum NumberValue {
    
    case Boolean(Bool)
    
    case Integer(Int)
    
    case Float(FloatValue)
    
    case Double(DoubleValue)
    
    public var rawValue: Any {
        
        switch self {
            
        case let .Boolean(value):   return value
        case let .Integer(value):   return value
        case let .Double(value):    return value
        case let .Float(value):     return value
        }
    }
}

public func ==(lhs: RelationshipValue, rhs: RelationshipValue) -> Bool {
    
    switch lhs {
        
    case let .ToOne(leftStr): switch rhs { case let .ToOne(rightStr): return leftStr == rightStr; default: return false }
        
    case let .ToMany(leftStrs): switch rhs { case let .ToMany(rightStrs): return leftStrs == rightStrs; default: return false }

    }
}

public enum RelationshipValue: Equatable {
    
    case ToOne(StringValue)
    
    case ToMany([StringValue])
    
    public var rawValue: Any {
        
        switch self {
            
        case let .ToOne(value):     return value
        case let .ToMany(value):    return value
        }
    }
}

// Typealiases to fix compiler error

public typealias DataValue = Data

public typealias DateValue = Date

