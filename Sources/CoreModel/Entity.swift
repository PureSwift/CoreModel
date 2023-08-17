//
//  Entity.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import Foundation

/// CoreModel Entity for Codable types
public protocol Entity: Codable, Identifiable where Self.ID: Codable, Self.ID: CustomStringConvertible, CodingKeys: Hashable {
    
    static var entityName: EntityName { get }
    
    static var attributes: [CodingKeys: AttributeType] { get }
    
    static var relationships: [CodingKeys: Relationship] { get }
    
    associatedtype CodingKeys: CodingKey
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
