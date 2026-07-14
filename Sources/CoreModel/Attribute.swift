//
//  Attribute.swift
//  
//
//  Created by Alsey Coleman Miller on 8/16/23.
//

/// CoreModel `Attribute`
public struct Attribute: Property, Equatable, Hashable, Identifiable, Sendable {

    public let id: PropertyKey

    public var type: AttributeType

    public init(
        id: PropertyKey,
        type: AttributeType
    ) {
        self.id = id
        self.type = type
    }
}

// MARK: - Codable

#if !hasFeature(Embedded)
extension Attribute: Codable {}
#endif
