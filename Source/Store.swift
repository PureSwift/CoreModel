//
//  Store.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/22/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

/// Defines the interface for **CoreModel**'s ```Store``` type.
public protocol Store {
    
    /// The model the persistent store will handle.
    var model: [Entity] { get }
    
    /// Queries the store for entities matching the fetch request.
    func fetch(fetchRequest: FetchRequest) throws -> [Resource]
    
    /// Determines whether the specified resource exists.
    func exists(resource: Resource) throws -> Bool
    
    /// Determines whether the specified resources exist.
    func exist(resources: [Resource]) throws -> Bool
    
    /// Creates an entity with the specified values.
    func create(entity entityName: String, initialValues: ValuesObject?) throws -> Resource
    
    /// Deletes the specified entity.
    func delete(resource: Resource) throws
    
    /// Edits the specified entity.
    func edit(resource: Resource, changes: ValuesObject) throws
    
    /// Returns the entity's values as a JSON object.
    func values(forResource resource: Resource) throws -> ValuesObject
}

/// Common errors for ```Store```.
public enum StoreError: ErrorType {
    
    /// The entity provided doesn't belong to the ```Store```'s schema.
    case InvalidEntity
    
    /// Invalid ```ValuesObject``` was given to the ```Store```.
    case InvalidValues
    
    /// The specified resource could not be found.
    case NotFound
}

// MARK: - Implementation

extension Store {
    
    func validate(values: ValuesObject, forEntity entity: Entity) -> Bool {
        
        // verify entity belongs to model
        guard (self.model.contains { (element: Entity) -> Bool in entity == entity })
            else { return false }
        
        for (key, value) in values {
            
            let attribute = entity.attributes.filter({ (element) -> Bool in element.name == key }).first
            
            let relationship = entity.relationships.filter({ (element) -> Bool in element.name == key }).first
            
            switch value {
                
            case .Null:
                if let attribute = attribute { guard attribute.optional else { return false }}
                if let relationship = relationship { guard relationship.optional else { return false }}
                return true
                
            case .Attribute(let attributeType):
                guard let attribute = attribute else { return false }
                
                
            }
            
            
            
            
            let attribute = entity.attributes.filter({ (element) -> Bool in element.name == key }).first
            
            let relationship = entity.relationships.filter({ (element) -> Bool in element.name == key }).first
            
            if let attribute = attribute {
                
                if value == Value.Null {
                    
                    guard value == Value.Null else { return false }
                }
                
                guard attribute.isOptional == false
                
                switch attribute.propertyType {
                    
                case .String:
                    switch value {
                        
                        
                    }
                }
            }
            
            if let relationship = relationship {
                
                guard (value == Value.Null && !attribute.optional) else { return false }
                
                
            }
            
            // property not found on entity
            return false
        }
        
        return true
    }
}

