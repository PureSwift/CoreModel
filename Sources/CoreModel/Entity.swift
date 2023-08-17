//
//  Entity.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

/// Defines the model for an entity
public struct EntityDescription: Codable, Identifiable, Hashable {
    
    public let id: EntityName
    
    public var attributes: [Attribute]
    
    public var relationships: [Relationship]
    
    public init(id: EntityName, attributes: [Attribute], relationships: [Relationship]) {
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }
}
