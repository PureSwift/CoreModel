//
//  EntityDescription.swift
//  
//
//  Created by Alsey Coleman Miller on 8/17/23.
//

import Foundation

/// Defines the model for an entity
public struct EntityDescription: Codable, Identifiable, Hashable, Sendable {
    
    public let id: EntityName
    
    public var attributes: [Attribute]
    
    public var relationships: [Relationship]
    
    public init(id: EntityName, attributes: [Attribute], relationships: [Relationship]) {
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }
}
