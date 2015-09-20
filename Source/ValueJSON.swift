//
//  ValueJSON.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/23/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import SwiftFoundation

private let ISO8601DateFormatter = DateFormatter(format: "yyyy-MM-dd'T'HH:mm:ssZZZZ")

/// Converts the values object to JSON
public extension Entity {
    
    /// Converts ```JSON``` to **CoreModel** values.
    ///
    /// - returns: The converted values or ```nil``` if the provided values do not match the entity's properties.
    func convert(values: JSONObject) -> ValuesObject? {
        
        var convertedValues = ValuesObject()
        
        for (key, jsonValue) in values {
            
            let attribute = self.attributes[key]
            
            let relationship = self.relationships[key]
            
            guard !(attribute == nil && relationship == nil) else { return nil }
            
            guard jsonValue != JSON.Value.Null else {
                
                convertedValues[key] = Value.Null
                
                continue
            }
            
            if let attribute = attribute {
                
                var attributeValue: AttributeValue!
                
                switch (jsonValue, attribute.type) {
                    
                case let (JSON.Value.String(value), AttributeType.String):
                    attributeValue = AttributeValue.String(value)
                    
                case let (JSON.Value.Number(.Boolean(value)), AttributeType.Number(.Boolean)):
                    attributeValue = AttributeValue.Number(.Boolean(value))
                    
                case let (JSON.Value.Number(.Integer(value)), AttributeType.Number(.Integer)):
                    attributeValue = AttributeValue.Number(.Integer(value))
                    
                case let (JSON.Value.Number(.Double(value)), AttributeType.Number(.Double)):
                    attributeValue = AttributeValue.Number(.Double(value))
                    
                case let (JSON.Value.String(value), AttributeType.Date):
                    
                    guard let date = ISO8601DateFormatter.valueFromString(value) else { return nil }
                    
                    attributeValue = AttributeValue.Date(date)
                    
                case let (JSON.Value.String(value), AttributeType.Data):
                    
                    let stringData = value.utf8.map({ (element) -> Byte in return element })
                    
                    let data = Base64.decode(stringData)
                    
                    attributeValue = AttributeValue.Data(data)
                    
                default: return nil
                    
                }
                
                assert(attributeValue != nil)
                
                convertedValues[key] = Value.Attribute(attributeValue)
            }
            
            if let relationship = relationship {
                
                var relationshipValue: RelationshipValue!
                
                switch (relationship.type, jsonValue) {
                    
                case let (.ToOne, JSON.Value.String(value)):
                    
                    relationshipValue = RelationshipValue.ToOne(value)
                    
                case let (.ToMany, JSON.Value.Array(value)):
                    
                    guard let resourceIDs = value.rawValues as? [String] else { return nil }
                    
                    relationshipValue = RelationshipValue.ToMany(resourceIDs)
                    
                default: return nil
                
                }
                
                assert(relationshipValue != nil)
                
                convertedValues[key] = Value.Relationship(relationshipValue)
            }
            
            // check that converted value was added
            assert(convertedValues[key] != nil)
        }
        
        return convertedValues
    }
}

public extension JSON {
    
    /// Converts **CoreModel** values to ```JSON```.
    static func fromValues(values: ValuesObject) -> JSONObject {
        
        var jsonObject = JSONObject()
        
        for (key, value) in values {
            
            let jsonValue = value.toJSON()
            
            jsonObject[key] = jsonValue
        }
        
        return jsonObject
    }
}

public extension Value {
    
    func toJSON() -> JSON.Value {
        
        switch self {
            
        // Null
            
        case Value.Null: return JSON.Value.Null
            
        // Attribute
            
        case let .Attribute(.String(value)):
            return JSON.Value.String(value)
            
        case let .Attribute(.Number(.Boolean(value))):
            return JSON.Value.Number(.Boolean(value))
            
        case let .Attribute(.Number(.Integer(value))):
            return JSON.Value.Number(.Integer(value))
            
        case let .Attribute(.Number(.Double(value))):
            return JSON.Value.Number(.Double(value))
            
        case let .Attribute(.Data(value)):
            
            let encodedData = Base64.encode(value)
            
            var encodedString = ""
            
            for byte in encodedData {
                
                let unicodeScalar = UnicodeScalar(byte)
                
                encodedString.append(unicodeScalar)
            }
            
            return JSON.Value.String(encodedString)
            
        case let .Attribute(.Date(value)):
            
            let dateString = ISO8601DateFormatter.stringFromValue(value)
            
            return JSON.Value.String(dateString)
            
        case let .Relationship(.ToOne(value)):
            
            return JSON.Value.String(value)
            
        case let .Relationship(.ToMany(value)):
            
            let jsonArray = value.map({ (element: String) -> JSON.Value in
                
                return JSON.Value.String(element)
            })
            
            return JSON.Value.Array(jsonArray)
        }
    }
}
