//
//  Entity.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import Foundation

/// CoreModel Entity for Codable types
public protocol Entity: Identifiable where CodingKeys: Hashable, Self.ID: ObjectIDConvertible {
    
    static var entityName: EntityName { get }
    
    static var attributes: [CodingKeys: AttributeType] { get }
    
    static var relationships: [CodingKeys: Relationship] { get }
    
    associatedtype CodingKeys: CodingKey
    
    init(from model: ModelData) throws
    
    func encode() throws -> ModelData
}

public extension Entity {
    
    static var entityName: EntityName {
        EntityName(rawValue: String(describing: Self.self))
    }
}

public extension Model {
    
    init(entities: any Entity.Type...) {
        self.init(entities: entities.map { .init(entity: $0) })
    }
}

public extension EntityDescription {
    
    init<T: Entity>(entity: T.Type) {
        let attributes = T.attributes
            .lazy
            .sorted { $0.key.stringValue < $1.key.stringValue }
            .map { Attribute(id: .init($0.key), type: $0.value) }
        let relationships = T.relationships
            .lazy
            .sorted { $0.key.stringValue < $1.key.stringValue }
            .map { $0.value }
        self.init(id: T.entityName, attributes: attributes, relationships: relationships)
    }
}
