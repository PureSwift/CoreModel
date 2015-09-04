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
    func create(resource: Resource, initialValues: ValuesObject?) throws
    
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

public extension Store {
    
    /// Attempts to validate setting the values object for an entity.
    func validate(values: ValuesObject, forEntity entity: Entity) throws {
        
        // verify entity belongs to model
        guard (self.model.contains { (element: Entity) -> Bool in entity == entity })
            else { throw StoreError.InvalidEntity }
        
        for (key, value) in values {
            
            let attribute = entity.attributes.filter({ (element) -> Bool in element.name == key }).first
            
            let relationship = entity.relationships.filter({ (element) -> Bool in element.name == key }).first
            
            // property not found on entity
            if attribute == nil && relationship == nil { throw StoreError.InvalidValues }
            
            switch value {
                
            case .Null:
                if let attribute = attribute { guard attribute.optional
                    else { throw StoreError.InvalidValues }}
                
                if let relationship = relationship { guard relationship.optional
                    else { throw StoreError.InvalidValues }}
                
            case .Attribute(let attributeValue):
                guard let attribute = attribute else { throw StoreError.InvalidValues }
                
                switch attributeValue {
                    
                case .String(_): guard attribute.propertyType == .String
                    else { throw StoreError.InvalidValues }
                    
                case .Date(_):   guard attribute.propertyType == .Date
                    else { throw StoreError.InvalidValues }
                    
                case .Data(_):   guard attribute.propertyType == .Data
                    else { throw StoreError.InvalidValues }
                    
                case .Number(let numberValue):
                    switch numberValue {
                        
                    case .Boolean(_): guard attribute.propertyType == .Number(.Boolean)
                        else { throw StoreError.InvalidValues }
                        
                    case .Integer(_): guard attribute.propertyType == .Number(.Integer)
                        else { throw StoreError.InvalidValues }
                        
                    case .Double(_):  guard attribute.propertyType == .Number(.Boolean)
                        else { throw StoreError.InvalidValues }
                    }
                }
                
            case .Relationship(let relationshipValue):
                guard let relationship = relationship else { throw StoreError.InvalidValues }
                
                switch relationshipValue {
                    
                case .ToOne(let value):
                    guard relationship.propertyType == .ToOne else { throw StoreError.InvalidValues }
                    
                    let resource = Resource(relationship.destinationEntityName, resourceID: value)
                    
                    guard try self.exists(resource) else { throw StoreError.InvalidValues }
                    
                case .ToMany(let value):
                    guard relationship.propertyType == .ToMany else { throw StoreError.InvalidValues }
                    
                    var resources = [Resource]()
                    
                    for resourceID in value {
                        
                        let resource = Resource(relationship.destinationEntityName, resourceID: resourceID)
                        
                        resources.append(resource)
                    }
                    
                    guard try self.exist(resources) else { throw StoreError.InvalidValues }
                }
            }
        }
    }
}

