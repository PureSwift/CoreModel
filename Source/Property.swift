//
//  Property.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

public protocol Property {
    
    typealias PropertyType
    
    var optional: Bool { get }
    
    var type: PropertyType { get }
}

public struct Attribute: Property, Equatable {
    
    public var optional: Bool
    
    public var type: AttributeType
    
    public init(type: AttributeType, optional: Bool = false) {
        
        self.type = type
        self.optional = optional
    }
}

public func == (lhs: Attribute, rhs: Attribute) -> Bool {
    
    return lhs.optional == rhs.optional && lhs.type == rhs.type
}

public struct Relationship: Property, Equatable {
    
    public var optional: Bool
    
    public var type: RelationshipType
    
    public var destinationEntityName: String
    
    public var inverseRelationshipName: String
    
    public init(type: RelationshipType,
        optional: Bool = false,
        destinationEntityName: String,
        inverseRelationshipName: String) {
        
        self.type = type
        self.optional = optional
        self.destinationEntityName = destinationEntityName
        self.inverseRelationshipName = inverseRelationshipName
    }
}

public func == (lhs: Relationship, rhs: Relationship) -> Bool {
    
    return lhs.optional == rhs.optional
        && lhs.type == rhs.type
        && lhs.destinationEntityName == rhs.destinationEntityName
        && lhs.inverseRelationshipName == rhs.inverseRelationshipName
}

