//
//  ToManyRelationship.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/25/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public struct ToManyRelationship<T: ManagedObject>: Relationship {
    
    public let name: String
    
    public let optional: Bool
    
    public let destinationEntity: Entity<T>
    
    public let toMany = true
}