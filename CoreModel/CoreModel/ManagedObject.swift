//
//  ManagedObject.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public protocol ManagedObject {
    
    // MARK: - Property Accessors
    
    func valueForAttribute(attribute: Attribute) -> Any
    
    func setValue(value: Any, forAttribute attribute: Attribute)
    
    func valueForToManyRelationship(relationship: Relationship) -> [ManagedObject]
    
    func setValue(value: [ManagedObject], forToManyRelationship relationship: Relationship)
    
    func valueForToOneRelationship(relationship: Relationship) -> ManagedObject
    
    func setValue(value: ManagedObject, forToOneRelationship relationship: Relationship)
}