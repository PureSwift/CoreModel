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
    
    /// Subentities
    static var subEntities: [Entity.Type]? { get }
    
    static var attributes: [String] { get }
    
    static var relationships: [String] { get }
}