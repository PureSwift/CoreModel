//
//  Relationship.swift
//  
//
//  Created by Alsey Coleman Miller on 8/16/23.
//

/// CoreModel `Relationship`
public struct Relationship: Property, Equatable, Hashable, Identifiable, Sendable {

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
public enum RelationshipType: String, CaseIterable, Sendable {

    case toOne
    case toMany
}

// MARK: - Codable

#if !hasFeature(Embedded)
extension Relationship: Codable {}
extension RelationshipType: Codable {}
#endif
