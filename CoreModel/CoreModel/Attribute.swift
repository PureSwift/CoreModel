//
//  Attribute.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public struct Attribute<T>: Property {
    
    public let propertyType: PropertyType = .Attribute
    
    public let name: String
    
    public let optional: Bool
        
    public let attributeType: AttributeType
    
    public init(name: String, attributeType: AttributeType, optional: Bool = true) {
        
        self.name = name
        self.optional = optional
        self.attributeType = attributeType
    }
    
    // MARK: - JSONCodable
    
    public static func fromJSON(JSONObject: [String: AnyObject]) -> Attribute<T>? {
        
        return nil
    }
    
    public func toJSON() -> JSONObject {
        
        var json = JSONObject()
        
        json[PropertyJSONKey.name.rawValue] = self.name
        
        json[PropertyJSONKey.optional.rawValue] = self.optional
        
        json[PropertyJSONKey.propertyType.rawValue] = self.propertyType.rawValue
        
        json[JSONKey.attributeType.rawValue] = self.attributeType.toJSON()
        
        return json
    }
}

private enum JSONKey: String {
    
    case attributeType = "attributeType"
}