//
//  Relationship.swift
//  
//
//  Created by Alsey Coleman Miller on 8/16/23.
//

import Foundation

/// CoreModel `Relationship`
public struct Relationship: Property, Codable, Equatable, Hashable, Identifiable, Sendable {
    
    public let id: PropertyKey
    
    public var type: RelationshipType
    
    public var destinationEntity: EntityName
    
    public var inverseRelationship: PropertyKey
    
    public init(id: PropertyKey,
                type: RelationshipType,
                destinationEntity: EntityName,
                inverseRelationship: PropertyKey) {
        
        self.id = id
        self.type = type
        self.destinationEntity = destinationEntity
        self.inverseRelationship = inverseRelationship
    }
}

/// CoreModel `Relationship` Type
public enum RelationshipType: String, Codable, CaseIterable, Sendable {
    
    case toOne
    case toMany
}
