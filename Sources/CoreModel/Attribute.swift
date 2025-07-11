//
//  Attribute.swift
//  
//
//  Created by Alsey Coleman Miller on 8/16/23.
//

import Foundation

/// CoreModel `Attribute`
public struct Attribute: Property, Codable, Equatable, Hashable, Identifiable, Sendable {
    
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
