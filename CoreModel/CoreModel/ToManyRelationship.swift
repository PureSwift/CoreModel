//
//  ToManyRelationship.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/25/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public struct ToManyRelationship<T: ManagedObject>: Relationship {
    
    public let toMany = true
    
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
        self.ordered = ordered
    }
    
    // MARK: - JSONCodable
    
    public static func fromJSON(JSONObject: [String: AnyObject]) -> ToManyRelationship<T>? {
        
        
        return nil
    }
    
    public func toJSON() -> JSONObject {
        
        
    }
}