//
//  Entity.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

/// Defines the model for an entity
public struct Entity: Equatable {
    
    public var attributes = [String: Attribute]()
    
    public var relationships = [String: Relationship]()
    
    public init() { }
}

public func == (lhs: Entity, rhs: Entity) -> Bool {
    
    return lhs.attributes == rhs.attributes && lhs.relationships == rhs.relationships
}