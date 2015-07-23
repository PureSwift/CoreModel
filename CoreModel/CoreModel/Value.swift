//
//  Value.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/23/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public typealias ValuesObject = [String: Value]

public enum Value {
    
    case Null
    
    case Attribute(AttributeValue)
    
    case Relationship(RelationshipValue)
}

public enum AttributeValue {
    
    case String(StringValue)
    
    case Number(NumberValue)
    
    //case Data(Data)
    
    //case Date(Date)
}

public enum NumberValue {
    
    case Boolean(Bool)
    
    case Integer(Int)
    
    //case Float(Float)
    
    //case Double(Double)
    
    //case Decimal(Decimal)
}

public enum RelationshipValue {
    
    case ToOne(StringValue)
    
    case ToMany([StringValue])
}

public typealias StringValue = String