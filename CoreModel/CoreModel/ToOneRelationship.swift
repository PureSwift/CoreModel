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
    
    public let destinationEntity: Entity<T>
    
    public init(name: String, destinationEntity: Entity<T>, optional: Bool = true) {
        
        self.name = name
        self.optional = optional
        self.destinationEntity = destinationEntity
    }
}