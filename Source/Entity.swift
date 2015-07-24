//
//  Entity.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

/// Defines the model for an entity
public struct Entity {
    
    // MARK: Model
    
    public var entityName: String
    
    public var attributes: [Attribute] = []
    
    public var relationships: [Relationship] = []
    
    public init(entityName: String) {
        
        self.entityName = entityName
    }
}