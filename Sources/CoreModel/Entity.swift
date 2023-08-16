//
//  Entity.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

/// Defines the model for an entity
public struct Entity: Codable, Equatable {
    
    public var name: String
    
    public var attributes: [Attribute]
    
    public var relationships: [Relationship]
    
    public init(
        name: String,
        attributes: [Attribute],
        relationships: [Relationship]
    ) {
        self.name = name
        self.attributes = attributes
        self.relationships = relationships
    }
}

public extension Entity {
    
    subscript (attribute propertyName: String) -> Attribute? {
        return attributes.first { $0.name == propertyName }
    }
    
    subscript (relationship propertyName: String) -> Relationship? {
        return relationships.first { $0.name == propertyName }
    }
}
