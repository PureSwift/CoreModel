//
//  Entity.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

/// Defines an interface for class or struct
public protocol Entity {
    
    static var entityName: String { get }
    
    /// Initializes an entity instance with the specified resource ID.
    init(resourceID: String)
    
    /// Resource ID. Shouldn't change in the life of the entity.
    var resourceID: String { get }
    
    var values: JSONObject { get }
    
    /// Attempts to sets the values. R
    func setValues(values: JSONObject) -> Bool
    
    // MARK: - Property Accessors
    
    func valueForAttribute<T>(attribute: Attribute<T>) -> T
    
    func setValue<T>(value: T, forAttribute attribute: Attribute<T>)
    
    func valueForToOneRelationship<T: ManagedObject>(relationship: ToOneRelationship<T>) -> T
    
    func setValue<T: ManagedObject>(value: T, forToOneRelationship relationship: ToOneRelationship<T>)
    
    func valueForToManyRelationship<T: ManagedObject>(relationship: ToManyRelationship<T>) -> [T]
    
    func setValue<T: ManagedObject>(value: [T], forToManyRelationship relationship: ToManyRelationship<T>)
}