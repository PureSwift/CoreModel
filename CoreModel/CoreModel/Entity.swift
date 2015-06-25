//
//  Entity.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public struct Entity<M: ManagedObject> {
    
    public let name: String
    
    public let abstract: Bool
    
    public let properties: [Property]
    
    public let attributes: [Attribute]
    
    public let relationships: [Relationship<M>]
    
    public let subentities: [Entity<M>]
}