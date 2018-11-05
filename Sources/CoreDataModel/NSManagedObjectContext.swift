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

extension NSManagedObjectContext: StoreProtocol {
    
    public func fetch(_ fetchRequest: FetchRequest) throws -> [NSManagedObject] {
        
        return try self.fetch(fetchRequest.toFoundation())
    }
    
    public func create(_ entityName: String) throws -> NSManagedObject {
        
        guard let model = self.persistentStoreCoordinator?.managedObjectModel
            else { fatalError("Invalid \(self)") }
        
        guard let entity = model.entitiesByName[entityName]
            else { throw StoreError.invalidEntity(entityName) }
        
        let managedObject = NSManagedObject(entity: entity, insertInto: self)
        
        return managedObject
    }
}

#endif
