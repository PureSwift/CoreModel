//
//  Value.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/23/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import SwiftFoundation

public typealias ValuesObject = [String: Value]

public enum Value: JSONEncodable {
    
    case Null
    
    case Attribute(AttributeValue)
    
    case Relationship(RelationshipValue)
    
    public var rawValue: Any {
        
        switch self {
            
        case Null: return Null()
        case let .Attribute(value): return value.rawValue
        case let .Relationship(value): return value.rawValue
        }
    }
}

public enum AttributeValue {
    
    case String(StringValue)
    
    case Number(NumberValue)
    
    case Data(DataValue)
    
    case Date(DateValue)
    
    public var rawValue: Any {
        
        switch self {
            
        case let .String(value):    return value
        case let .Data(value):      return value
        case let .Date(value):      return value
        case let .Number(value):    return value.rawValue
        }
    }
}

public enum NumberValue {
    
    case Boolean(Bool)
    
    case Integer(Int)
    
    case Double(DoubleValue)
    
    public var rawValue: Any {
        
        switch self {
            
        case let .Boolean(value):   return value
        case let .Integer(value):   return value
        case let .Double(value):    return value
        }
    }
}

public enum RelationshipValue {
    
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

