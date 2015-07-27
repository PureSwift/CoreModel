//
//  CoreDataStore.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/23/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

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
    
    public init?(managedObjectContext: NSManagedObjectContext) {
        
        guard let model = managedObjectContext.persistentStoreCoordinator?.managedObjectModel.toModel()
            else { return nil }
        
        self.model = model
        self.managedObjectContext = managedObjectContext
    }
    
    // MARK: - Store
    
    public let model: [Entity]
    
    public func exists(resource: Resource) throws -> Bool {
        
        guard let entity = self.managedObjectContext.persistentStoreCoordinator?.managedObjectModel.entitiesByName[resource.entityName] else { throw StoreError.InvalidEntity }
        
        var exists: Bool = false
        
        try self.managedObjectContext.performErrorBlockAndWait({ () -> Void in
            
            exists = (try self.findEntity(entity, withResourceID: resource.resourceID) != nil)
        })
        
        return exists
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
    
    public func values(forResource resource: Resource) throws -> ValuesObject {
        
        
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




