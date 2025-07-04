//
//  Entity.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import Foundation

/// CoreModel Entity for Codable types
public protocol Entity: Identifiable, Sendable where CodingKeys: Hashable, Self.ID: ObjectIDConvertible {
    
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
    
    static var attributes: [CodingKeys: AttributeType] { [:] }
    
    static var relationships: [CodingKeys: Relationship] { [:] }
}

public extension Model {
    
    init(entities: any Entity.Type...) {
        self.init(entities: entities.map { .init(entity: $0) })
    }
}

public extension EntityDescription {
    
    init<T: Entity>(entity: T.Type) {
        let attributes = T.attributes
            .map { Attribute(id: .init($0.key), type: $0.value) }
        let relationships = T.relationships
            .map { $0.value }
        self.init(id: T.entityName, attributes: attributes, relationships: relationships)
    }
}

public extension Relationship {
    
    init<Entity, DestinationEntity>(
        id: Entity.CodingKeys,
        entity: Entity.Type,
        destination: DestinationEntity.Type,
        type: RelationshipType,
        inverseRelationship: DestinationEntity.CodingKeys
    ) where Entity: CoreModel.Entity, DestinationEntity: CoreModel.Entity {
        self.init(
            id: PropertyKey(id),
            type: type,
            destinationEntity: destination.entityName,
            inverseRelationship: PropertyKey(inverseRelationship)
        )
    }
}
