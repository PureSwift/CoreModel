//
//  AttributeType.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

/** The attributes types availible in Core Model. */
public enum AttributeType {
    
    /** Number type. Specific subset availible. */
    case Number(NumberType)
    
    /** String attribute type. */
    case String
    
    /** Date attribute type. */
    case Date
    
    /** Binary Data attribute type. */
    case Data
    
    /** Attribute can be transformed from and to binary data using a value transformer. The associated value is the value transformer to use. */
    case Transformable(ValueTransformer)
}

/** A subset of attribute types belonging to numbers. */
public enum NumberType {
    
    /** Boolean number type. */
    case Boolean
    
    /** Integer number type. */
    case Integer
    
    /** Decimal (floating point) number type. */
    case Decimal
}