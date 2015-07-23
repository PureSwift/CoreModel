//
//  Entity.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

/// Defines an interface for class or struct
public protocol Entity {
    
    // MARK: Static Model
    
    static var entityName: String { get }
    
    static var attributes: [String] { get }
    
    static var relationships: [String] { get }
    
    /// Initializes an entity instance with the specified resource ID.
    init(resourceID: String)
    
    /// Resource ID. Shouldn't change in the life of the entity.
    var resourceID: String { get }
}