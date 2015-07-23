//
//  Value.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/23/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public typealias ValuesObject = [String: Value]

public enum Value {
    
    case Attribute(AttributeValue)
    
    case Relationship(RelationshipValue)
}

public enum AttributeValue {
    
    case Null
    
    case String(StringValue)
    
    case Number(NumberValue)
    
    //case Data([UInt8])
    
    //case Date(Date)
    
    //case Transformable([UInt8], String)
}

public enum NumberValue {
    
    case Boolean(Bool)
    
    case Integer(Int)
    
    //case Float(Float)
    
    //case Double(Double)
    
    //case Decimal(Decimal)
}

public enum RelationshipValue {
    
    case ToOne((String, String))
    
    case ToMany([(String, String)])
}

public typealias StringValue = String