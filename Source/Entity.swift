//
//  Entity.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

/// Defines the model for an entity
public struct Entity: Equatable {
    
    // MARK: Model
    
    public var name: String
    
    public var attributes: [Attribute] = []
    
    public var relationships: [Relationship] = []
    
    public init(entityName: String) {
        
        self.name = entityName
    }
}

public func == (lhs: Entity, rhs: Entity) -> Bool {
    
    return lhs.name == rhs.name && lhs.attributes == rhs.attributes && lhs.relationships == rhs.relationships
}