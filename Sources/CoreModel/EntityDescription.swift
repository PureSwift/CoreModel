//
//  EntityDescription.swift
//  
//
//  Created by Alsey Coleman Miller on 8/17/23.
//

/// Defines the model for an entity
public struct EntityDescription: Identifiable, Hashable, Sendable {

    public let id: EntityName

    public var attributes: [Attribute]

    public var relationships: [Relationship]

    public init(id: EntityName, attributes: [Attribute], relationships: [Relationship]) {
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }
}

// MARK: - Property Resolution

public extension EntityDescription {

    /// The attribute with the given name.
    subscript(attribute id: PropertyKey) -> Attribute? {
        attributes.first { $0.id == id }
    }

    /// The relationship with the given name.
    subscript(relationship id: PropertyKey) -> Relationship? {
        relationships.first { $0.id == id }
    }

    /// Resolve a key path to the attribute it addresses, descending through the
    /// elements of composite attributes.
    ///
    /// - Returns: `nil` for paths that leave the attribute graph — a relationship
    /// component, an index or operator component, or a name that no element declares.
    func attribute(for keyPath: PredicateKeyPath) -> Attribute? {
        guard case let .property(first)? = keyPath.keys.first,
            var current = self[attribute: PropertyKey(rawValue: first)] else {
            return nil
        }
        for key in keyPath.keys.dropFirst() {
            guard case let .property(name) = key,
                let next = current[element: PropertyKey(rawValue: name)] else {
                return nil
            }
            current = next
        }
        return current
    }
}

// MARK: - Codable

#if !hasFeature(Embedded)
extension EntityDescription: Codable {}
#endif
