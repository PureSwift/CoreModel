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
    
    // MARK: Instance
    
    /// Initializes an entity instance with the specified resource ID.
    init(resourceID: String)
    
    /// Resource ID. Shouldn't change in the life of the entity.
    var resourceID: String { get }
}