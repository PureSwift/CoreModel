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
    
    public let destinationEntity: Entity<T>
    
    public let ordered: Bool
    
    public init(name: String, destinationEntity: Entity<T>, ordered: Bool = false, optional: Bool = true) {
        
        self.name = name
        self.optional = optional
        self.destinationEntity = destinationEntity
        self.ordered = false
    }
}