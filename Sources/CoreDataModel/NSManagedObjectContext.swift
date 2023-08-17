//
//  NSManagedObjectContext.swift
//  CoreDataModel
//
//  Created by Alsey Coleman Miller on 11/4/18.
//

#if canImport(CoreData)

import Foundation
import CoreData
import CoreModel
import Predicate

public final class CoreDataStore: StoreProtocol {
    
    public let context: NSManagedObjectContext
    
    public init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    /// Fetch managed objects.
    public func fetch(_ fetchRequest: FetchRequest) throws -> [CoreDataManagedObject] {
        return try context.fetch(fetchRequest).map { CoreDataManagedObject($0) }
    }
    
    /// Fetch and return result count.
    public func count(for fetchRequest: FetchRequest) throws -> Int {
        return try context.count(for: fetchRequest)
    }
    
    /// Create new managed object.
    public func create(_ entity: String) throws -> CoreDataManagedObject {
        let managedObject = try context.create(entity)
        return CoreDataManagedObject(managedObject)
    }
    
    /// Delete the specified managed object.
    public func delete(_ managedObject: CoreDataManagedObject) {
        context.delete(managedObject.managedObject)
    }
    
    /// Flush the store's pending changes to the underlying storage format.
    public func save() throws {
        try context.save()
    }
}

internal extension NSManagedObjectContext {
    
    func fetch(_ fetchRequest: FetchRequest) throws -> [NSManagedObject] {
        return try self.fetch(fetchRequest.toFoundation())
    }
    
    func count(for fetchRequest: FetchRequest) throws -> Int {
        return try self.count(for: fetchRequest.toFoundation())
    }
    
    func create(_ entityName: String) throws -> NSManagedObject {
        
        guard let model = self.persistentStoreCoordinator?.managedObjectModel
            else { fatalError("Invalid \(self)") }
        
        guard let entity = model.entitiesByName[entityName]
            else { throw StoreError.invalidEntity(entityName) }
        
        let managedObject = NSManagedObject(entity: entity, insertInto: self)
        return managedObject
    }
}

#endif
