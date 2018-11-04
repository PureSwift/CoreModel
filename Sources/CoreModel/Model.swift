//
//  Model.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 11/4/18.
//

import Foundation

/**
 The model contains one or more `Entity` objects representing the entities in the schema.
 */
public struct Model: Codable {
    
    public var entities: [Entity]
    
    public init(entities: [Entity] = []) {
        
        self.entities = entities
    }
}

public extension Model {
    
    subscript (entityName: String) -> Entity? {
        
        return entities.first { $0.name == entityName }
    }
}
