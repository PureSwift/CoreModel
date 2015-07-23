//
//  Value.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/23/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation

public typealias ValuesObject = [String: Value]

public enum Value {
    
    case Null
    
    case Attribute(AttributeValue)
    
    case Relationship(RelationshipValue)
}

public enum AttributeValue {
    
    case String(StringValue)
    
    case Number(NumberValue)
    
    case Data(DataValue)
    
    case Date(DateValue)
}

public enum NumberValue {
    
    case Boolean(Bool)
    
    case Integer(Int)
    
    case Float(FloatValue)
    
    case Double(DoubleValue)
    
    case Decimal(DecimalValue)
}

public enum RelationshipValue {
    
    case ToOne(StringValue)
    
    case ToMany([StringValue])
}

// Typealises to fix compiler error

public typealias DataValue = Data

public typealias DateValue = Date