//
//  CoreDataStore.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/23/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

#if os(OSX)

import Foundation
import CoreData

/// **CoreData**-backed **CoreModel** ```Store``` implementation.
public final class CoreDataStore: Store {
    
    // MARK: - Properties
    
    /// The managed object context this ```Store``` is backed by.
    public let managedObjectContext: NSManagedObjectContext
    
    /// Name of the attribute that all entities have that will be used for uniquing.
    public let resourceIDAttributeName: String
    
    // MARK: - Initialization
    
    /// Creates a Store backed by a **CoreData** managed object context.
    ///
    /// - Note: The provided managed object context have its own ```NSPersistentCoordinator``` setup and the **CoreData** managed object model must match the provided model with the exception that the managed object model must contain an extra *resource ID* attribute for each entity.
    public init?(model: Model, managedObjectContext: NSManagedObjectContext, resourceIDAttributeName: String = "id") {
        
        self.model = model
        self.managedObjectContext = managedObjectContext
        self.resourceIDAttributeName = resourceIDAttributeName
    }
    
    // MARK: - Store
    
    public let model: Model
    
    public func fetch(fetchRequest: FetchRequest) throws -> [Resource] {
        
        var resources = [Resource]()
        
        try self.managedObjectContext.performErrorBlockAndWait({ () -> Void in
            
            let fetchRequest = try NSFetchRequest(fetchRequest: fetchRequest, store: self)
            
            fetchRequest.resultType = NSFetchRequestResultType.ManagedObjectIDResultType
            
            let results = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [NSManagedObjectID]
            
            for objectID in results {
                
                let managedObject = self.managedObjectContext.objectWithID(objectID)
                
                let resourceID = managedObject.valueForKey(self.resourceIDAttributeName) as! String
                
                let resource = Resource(managedObject.entity.name!, resourceID)
                
                resources.append(resource)
            }
        })
        
        return resources
    }
    
    public func exists(resource: Resource) throws -> Bool {
        
        guard let entity = self.managedObjectContext.persistentStoreCoordinator?.managedObjectModel.entitiesByName[resource.entityName] else { throw StoreError.InvalidEntity }
        
        var exists: Bool = false
        
        try self.managedObjectContext.performErrorBlockAndWait({ () -> Void in
            
            exists = (try self.findEntity(entity, withResourceID: resource.resourceID) != nil)
        })
        
        return exists
    }
    
    public func exist(resources: [Resource]) throws -> Bool {
        
        for resource in resources {
            
            guard try self.exists(resource) else { return false }
        }
        
        return true
    }
    
    public func create(resource: Resource, initialValues: ValuesObject) throws {
        
        guard self.managedObjectContext.persistentStoreCoordinator?.managedObjectModel.entitiesByName[resource.entityName] != nil else { throw StoreError.InvalidEntity }
        
        try self.managedObjectContext.performErrorBlockAndWait({ () -> Void in
            
            // create managed object
            let managedObject = NSEntityDescription.insertNewObjectForEntityForName(resource.entityName, inManagedObjectContext: self.managedObjectContext)
            
            // set resource ID
            managedObject.setValue(resource.resourceID, forKey: self.resourceIDAttributeName)
            
            // set initial values
            try managedObject.setValues(initialValues, store: self)
            
            // save
            try self.managedObjectContext.save()
        })
    }
    
    public func delete(resource: Resource) throws {
        
        guard let entity = self.managedObjectContext.persistentStoreCoordinator?.managedObjectModel.entitiesByName[resource.entityName] else { throw StoreError.InvalidEntity }
        
        try self.managedObjectContext.performErrorBlockAndWait { () -> Void in
            
            guard let managedObjectID = try self.findEntity(entity, withResourceID: resource.resourceID)
                else { throw StoreError.NotFound }
            
            let managedObject = self.managedObjectContext.objectWithID(managedObjectID)
            
            self.managedObjectContext.deleteObject(managedObject)
            
            try self.managedObjectContext.save()
        }
    }
    
    public func edit(resource: Resource, changes: ValuesObject) throws {
        
        guard let entity = self.managedObjectContext.persistentStoreCoordinator?.managedObjectModel.entitiesByName[resource.entityName] else { throw StoreError.InvalidEntity }
        
        try self.managedObjectContext.performErrorBlockAndWait({ () -> Void in
            
            guard let objectID = try self.findEntity(entity, withResourceID: resource.resourceID)
                else { throw StoreError.NotFound }
            
            let managedObject = self.managedObjectContext.objectWithID(objectID)
            
            try managedObject.setValues(changes, store: self)
            
            try self.managedObjectContext.save()
        })
    }
    
    public func values(resource: Resource) throws -> ValuesObject {
        
        guard let entity = self.managedObjectContext.persistentStoreCoordinator?.managedObjectModel.entitiesByName[resource.entityName] else { throw StoreError.InvalidEntity }
        
        var values: ValuesObject!
        
        try self.managedObjectContext.performErrorBlockAndWait { () -> Void in
            
            guard let objectID = try self.findEntity(entity, withResourceID: resource.resourceID)
                else { throw StoreError.NotFound }
            
            let managedObject = self.managedObjectContext.objectWithID(objectID)
            
            values = try managedObject.values(self)
        }
        
        return values
    }
    
    // MARK: - Utility
    
    public func findEntity(entity: NSEntityDescription, withResourceID resourceID: String) throws -> NSManagedObjectID? {
        
        // get cached resource...
        
        let fetchRequest = NSFetchRequest(entityName: entity.name!)
        
        fetchRequest.fetchLimit = 1
        
        fetchRequest.resultType = NSFetchRequestResultType.ManagedObjectIDResultType
        
        fetchRequest.includesSubentities = false
        
        // create predicate
        
        fetchRequest.predicate = NSComparisonPredicate(leftExpression: NSExpression(forKeyPath: self.resourceIDAttributeName), rightExpression: NSExpression(forConstantValue: resourceID), modifier: NSComparisonPredicateModifier.DirectPredicateModifier, type: NSPredicateOperatorType.EqualToPredicateOperatorType, options: NSComparisonPredicateOptions.NormalizedPredicateOption)
        
        // fetch
        
        let results = try managedObjectContext.executeFetchRequest(fetchRequest) as! [NSManagedObjectID]
        
        let objectID = results.first
        
        return objectID
    }
}

#endif


