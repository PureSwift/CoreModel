//
//  ManagedObject.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public protocol ManagedObject {
    
    // MARK: - Property Accessors
    
    func valueForAttribute<T>(attribute: Attribute<T>) -> T
    
    func setValue<T>(value: T, forAttribute attribute: Attribute<T>)
    
    func valueForToOneRelationship<T: ManagedObject>(relationship: ToOneRelationship<T>) -> T
    
    func setValue<T: ManagedObject>(value: T, forToOneRelationship relationship: ToOneRelationship<T>)
    
    func valueForToManyRelationship<T: ManagedObject>(relationship: ToManyRelationship<T>) -> [T]
    
    func setValue<T: ManagedObject>(value: [T], forToManyRelationship relationship: ToManyRelationship<T>)
}