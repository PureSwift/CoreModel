//
//  ToOneRelationship.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/25/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public struct ToOneRelationship<T: ManagedObject>: Relationship {
    
    public let toMany = false
    
    public let name: String
    
    public let optional: Bool
    
    public let destinationEntityName: String
    
    public let inverseRelationshipName: String
    
    public let ordered: Bool
    
    public init(name: String, destinationEntityName: String, inverseRelationshipName: String, ordered: Bool = false, optional: Bool = true) {
        
        self.name = name
        self.optional = optional
        self.destinationEntityName = destinationEntityName
        self.inverseRelationshipName = inverseRelationshipName
    }
    
    // MARK: - JSONCodable
    
    public static func fromJSON(JSONObject: JSONObject) -> ToOneRelationship<T>? {
        
        
        return nil
    }
    
    public func toJSON() -> JSONObject {
        
        
    }
}