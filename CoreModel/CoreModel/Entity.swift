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
    
    public let subentities: [Entity<T>]
    
    public init(name: String, abstract: Bool = false, properties: [Property], subentities: [Entity<T>]) {
        
        self.name = name
        self.abstract = abstract
        self.properties = properties
        self.subentities = subentities
    }
    
    // MARK: - JSONCodable
    
    public static func fromJSON(JSONObject: JSONObject) -> Model {
        
        
    }
    
    public func toJSON() -> [String: AnyObject] {
        
        
    }
}