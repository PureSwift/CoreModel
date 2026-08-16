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

// MARK: - Composite

public extension Attribute {

    /// Creates a composite attribute from its elements.
    init(id: PropertyKey, elements: [Attribute]) {
        self.init(id: id, type: .composite(elements))
    }

    /// Creates a composite attribute from a type that describes its own elements.
    init<T>(id: PropertyKey, composite type: T.Type) where T: CompositeAttribute {
        self.init(id: id, type: T.attributeType)
    }

    /// The elements of this attribute, if it is composite.
    var elements: [Attribute]? {
        type.elements
    }

    /// The element with the given name, if this attribute is composite.
    subscript(element id: PropertyKey) -> Attribute? {
        type.elements?.first { $0.id == id }
    }
}

// MARK: - Codable

#if !hasFeature(Embedded)
extension Attribute: Codable {}
#endif
