//
//  AttributeType.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

/** The attributes types availible in Core Model. */
public enum AttributeType: JSONCodable {
    
    /** Number type. Specific subset availible. */
    case Number(NumberType)
    
    /** String attribute type. */
    case String
    
    /** Date attribute type. */
    case Date
    
    /** Binary Data attribute type. */
    case Data
    
    /** Attribute can be transformed from and to binary data using a value transformer. The associated value is the value transformer to use. */
    case Transformable(StringAlias)
    
    public func typeName() -> StringAlias {
        
        switch self {
            
        case .Number(_):
            return "Number"
            
        case .String:
            return "String"
            
        case .Date:
            return "Date"
            
        case .Data:
            return "Data"
            
        case .Transformable(_):
            return "Transformable"
        }
    }
    
    // MARK: - JSONCodable
    
    public static func fromJSON(JSONObject: [StringAlias: AnyObject]) -> AttributeType? {
        
        return nil
    }
    
    public func toJSON() -> JSONObject {
        
        var json = JSONObject()
        
        return json
    }
}

/** A subset of attribute types belonging to numbers. */
public enum NumberType: String {
    
    /** Boolean number type. */
    case Boolean
    
    /** Integer number type. */
    case Integer
    
    /** Floating point number type. */
    case Float
    
    /** Floating point number type. */
    case Double
    
    /** Floating point number type. */
    case Decimal
}

private enum JSONKey: String {
    
    case type = "type"
    
    case value = "value"
}

// TODO: Remove compiler fix for missing string type. */
public typealias StringAlias = String
