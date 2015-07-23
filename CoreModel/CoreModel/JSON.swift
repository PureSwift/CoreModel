//
//  JSON.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/25/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public typealias JSONArray = [JSONValue]

public typealias JSONObject = [String: JSONValue]

public enum JSONValue: RawRepresentable {
    
    case Null
    
    /// JSON value is a String Value
    case String(JSONString)
    
    /// JSON value is a Number Value (specific subtypes)
    case Number(JSONNumber)
    
    /// JSON value is an Array of other JSON values
    case Array(JSONArray)
    
    /// JSON value a JSON object
    case Object(JSONObject)
    
    // MARK: RawRepresentable
    
    public var rawValue: Any {
        
        switch self {
            
        case .Null: return Null
            
        case .String(let string): return string
            
        case .Number(let number): return number.rawValue
            
        case .Array(let array): return array
        }
    }
    
    public init?(rawValue: Any) {
        
        
    }
}

public enum JSONNumber: RawRepresentable {
    
    case Boolean(Bool)
    
    case Integer(Int)
    
    // MARK: RawRepresentable
    
    public var rawValue: Any {
        
        
    }
    
    public init?(rawValue: Any) {
        
        
    }
}

// Typealiases only due to compiler error

public typealias JSONString = String

public protocol JSONCodable {
    
    
}