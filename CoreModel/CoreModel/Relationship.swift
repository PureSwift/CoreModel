//
//  Relationship.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public protocol Relationship: Property {
    
    var destinationEntityName: String { get }
    
    var inverseRelationshipName: String { get }
    
    var toMany: Bool { get }
}

public extension Relationship {
    
    public var propertyType: PropertyType { return .Relationship }
}

internal enum RelationshipJSONKey: String {
    
    case destinationEntityName = "destinationEntityName"
    case inverseRelationshipName = "inverseRelationshipName"
    case toMany = "toMany"
}