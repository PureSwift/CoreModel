//
//  Entity.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

/// Defines the model for an entity
public protocol Entity {
    
    // MARK: Model
    
    /// Entity's name
    static var entityName: String { get }
    
    static var attributes: [Attribute] { get }
    
    static var relationships: [Relationship] { get }
}