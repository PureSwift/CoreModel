//
//  Entity.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public struct Entity<T: ManagedObject>: JSONCodable {
    
    public let name: String
    
    public let abstract: Bool
    
    public let properties: [Property]
    
    public let subentities: [Entity<T>]?
    
    public init(name: String, abstract: Bool = false, properties: [Property], subentities: [Entity<T>]? = nil) {
        
        self.name = name
        self.abstract = abstract
        self.properties = properties
        self.subentities = subentities
    }
    
    // MARK: - JSONCodable
    
    public static func fromJSON(JSONObject: [String: AnyObject]) -> Entity<T>? {
        
        return nil
    }
    
    public func toJSON() -> [String: AnyObject] {
        
        var jsonObject = JSONObject()
        
        jsonObject[JSONKey.name.rawValue] = self.name
        
        jsonObject[JSONKey.abstract.rawValue] = self.abstract
        
        jsonObject[JSONKey.properties.rawValue] = {
            
            var propertiesJSON = [JSONObject]()
            
            for property in self.properties {
                
                propertiesJSON.append(property.toJSON())
            }
            
            return propertiesJSON
            }() as [JSONObject]
        
        if let subentities = self.subentities {
            
            jsonObject[JSONKey.subentities.rawValue] = {
                
                var subentitiesJSON = [JSONObject]()
                
                for entity in subentities {
                    
                    subentitiesJSON.append(entity.toJSON())
                }
                
                return subentitiesJSON
                
                }() as [JSONObject]
        }
        
        return jsonObject
    }
}

private enum JSONKey: String {
        
        case name = "name"
        case abstract = "abstract"
        case properties = "properties"
        case subentities = "subentities"
}