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
public struct Model: Hashable, Sendable {
    
    public var entities: [EntityDescription]
    
    public init(entities: [EntityDescription] = []) {
        self.entities = entities
    }
}

public extension Model {
    
    subscript (id: EntityName) -> EntityDescription? {
        return entities.first { $0.id == id }
    }
}

// MARK: - Codable

extension Model: Codable {
    
    public init(from decoder: Decoder) throws {
        self.entities = try .init(from: decoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        try entities.encode(to: encoder)
    }
}
