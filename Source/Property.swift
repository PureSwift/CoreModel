//
//  Property.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

public protocol Property {
    
    typealias PropertyType
    
    var type: PropertyType { get }
}

public struct Attribute: Property, Equatable {
    
    public var type: AttributeType
    
    public init(type: AttributeType) {
        
        self.type = type
    }
}

public func == (lhs: Attribute, rhs: Attribute) -> Bool {
    
    return lhs.type == rhs.type
}

public struct Relationship: Property, Equatable {
    
    public var type: RelationshipType
    
    public var destinationEntityName: String
    
    public var inverseRelationshipName: String
    
    public init(type: RelationshipType,
        destinationEntityName: String,
        inverseRelationshipName: String) {
        
        self.type = type
        self.destinationEntityName = destinationEntityName
        self.inverseRelationshipName = inverseRelationshipName
    }
}

public func == (lhs: Relationship, rhs: Relationship) -> Bool {
    
    return lhs.type == rhs.type
        && lhs.destinationEntityName == rhs.destinationEntityName
        && lhs.inverseRelationshipName == rhs.inverseRelationshipName
}

