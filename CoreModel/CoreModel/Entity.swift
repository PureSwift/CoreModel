//
//  Entity.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public struct Entity<T: ManagedObject> {
    
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
}

extension Entity: JSONCodable {
    
    public func toBriefJSON() -> String {
        
        return self.name
    }
    
    // MARK: - JSONCodable
    
    public static func fromJSON(JSONObject: [String: AnyObject]) -> Entity<T>? {
        
        return nil
    }
    
    public func toJSON() -> [String: AnyObject] {
        
        
    }
}