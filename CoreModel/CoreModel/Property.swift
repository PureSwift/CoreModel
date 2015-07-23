//
//  Property.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public protocol Property {
    
    typealias PropertyType
    
    var name: String { get }
    
    var optional: Bool { get }
    
    var propertyType: PropertyType { get }
}

public struct Attribute {
    
    var name: String
    
    var optional: Bool = false
    
    var propertyType: AttributeType
}

public struct Relationship {
    
    var name: String
    
    var optional: Bool = false
    
    var propertyType: RelationshipType
    
    var destinationEntityName: String
    
    var inverseRelationshipName: String
}