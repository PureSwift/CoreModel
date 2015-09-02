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
    
    /// Converts ```JSON``` to *CoreModel* values. 
    ///
    /// - returns: The converted values or ```nil``` if the provided values do not match the entity's properties.
    func convert(values: JSONObject) -> ValuesObject? {
        
        var convertedValues = ValuesObject()
        
        for (key, jsonValue) in values {
            
            let attribute = self.attributes.filter({ (element) -> Bool in
                
                return (element.name == key)
                
            }).first
            
            let relationship = self.relationships.filter({ (element) -> Bool in
                
                return (element.name == key)
                
            }).first
            
            guard !(attribute == nil && relationship == nil) else { return nil }
            
            guard jsonValue != JSON.Value.Null else {
                
                convertedValues[key] = AttributeValue.Null
                
                continue
            }
            
            if let attribute = attribute {
                
                var attributeValue: AttributeValue!
                
                switch (jsonValue, attribute.propertyType) {
                    
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
                
                switch (relationship.propertyType, jsonValue) {
                    
                case let (.ToOne, JSON.Value.String(value)):
                    
                    guard let resource = Resource(JSONValue: json) else { return nil }
                    
                    relationshipValue = RelationshipValue.ToOne(<#T##StringValue#>)
                }
                
                assert(relationshipValue != nil)
                
                convertedValues[key] = Value.Relationship(relationshipValue)
            }
            
            // check that converted value was added
            assert(convertedValues[key] != nil)
        }
        
        
    }
}

public extension JSON {
    
    /// Converts **CoreModel** values to ```JSON```.
    static func fromValues(values: ValuesObject) -> JSONObject {
        
        return JSONObject()
    }
}