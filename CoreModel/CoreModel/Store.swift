//
//  Store.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/22/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

/// Defines the interface for CoreModel's Store type.
public protocol Store {
    
    /// The model the persistent store will handle.
    var model: [Entity] { get }
    
    /// Queries the store for entities matching the fetch request.
    func fetch(fetchRequest: FetchRequest) throws -> [Resource]
    
    /// Fetches the specified specified by resource ID.
    func fetch(entity entityName: String, withResourceID resourceID: String) throws -> Resource?
    
    /// Fetches the entities specified in the resource IDs.
    func fetch(entity entityName: String, withResourceIDs resourceIDs: [String]) throws -> [Resource]
    
    /// Creates the specified entity
    func create(entity entityName: String, initialValues: ValuesObject?) throws -> Resource
    
    /// Deletes the specified entity.
    func delete(resource: Resource) throws
    
    /// Edits the specified entity.
    func edit(resource: Resource, changes: ValuesObject) throws
    
    /// Returns the entity's values as a JSON object.
    func values(forResource resource: Resource) throws -> ValuesObject
}