//
//  Property.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

/// CoreModel Property
public protocol Property {
    
    associatedtype PropertyType
    
    var name: String { get }
    
    var type: PropertyType { get }
}

/// CoreModel Attribute
public struct Attribute: Property, Equatable, Codable {
    
    public var name: String
    
    public var type: AttributeType
    
    public init(name: String, type: AttributeType) {
        
        self.name = name
        self.type = type
    }
}

/// CoreModel Attribute type
public enum AttributeType: String, Codable {
    
    /// Boolean number type.
    case boolean
    
    /// 16 bit Integer number type.
    case int16
    
    /// Integer number type.
    case int32
    
    /// Integer number type.
    case int64
    
    /// Floating point number type.
    case float
    
    /// Floating point number type.
    case double
    
    /// Attribute is a string.
    case string
    
    /// Attribute is binary data.
    case data
    
    /// Attribute is a date.
    case date
}

/// CoreModel Relationship
public struct Relationship: Property, Equatable, Codable {
    
    public var name: String
    
    public var type: RelationshipType
    
    public var destinationEntity: String
    
    public var inverseRelationship: String
    
    public init(name: String,
                type: RelationshipType,
                destinationEntity: String,
                inverseRelationship: String) {
        
        self.name = name
        self.type = type
        self.destinationEntity = destinationEntity
        self.inverseRelationship = inverseRelationship
    }
}

/// CoreModel Relationship Type
public enum RelationshipType: String, Codable {
    
    case toOne
    case toMany
}
