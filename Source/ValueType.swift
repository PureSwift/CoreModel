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

public enum AttributeType {
    
    /// Attribute is a string.
    case String
    
    /// Attribute is a number.
    case Number(NumberType)
    
    /// Attribute is binary data.
    case Data
    
    /// Attribute is a date.
    case Date
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
    
    /// Floating point number type.
    case Decimal
}

// Type of relationship
public enum RelationshipType: String {
    
    case ToOne
    case ToMany
}