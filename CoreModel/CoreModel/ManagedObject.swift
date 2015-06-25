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
    
    func valueForToOneRelationship<T: ManagedObject>(relationship: ToOneRelationship<T>) -> T
    
    func setValue<T: ManagedObject>(value: T, forToOneRelationship relationship: ToOneRelationship<T>)
    
    func valueForToManyRelationship<T: ManagedObject>(relationship: ToManyRelationship<T>) -> [T]
    
    func setValue<T: ManagedObject>(value: [T], forToManyRelationship relationship: ToManyRelationship<T>)
}