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

extension NSManagedObjectContext: ModelStorage {
    
    public func fetch(_ entity: EntityName, for id: ObjectID) throws -> ModelInstance? {
        guard let model = self.persistentStoreCoordinator?.managedObjectModel else {
            assertionFailure("Missing model")
            throw CocoaError(.coreData)
        }
        guard let managedObject = try self.find(entity, for: id, in: model) else {
            return nil
        }
        return try ModelInstance(managedObject: managedObject)
    }
    
    public func fetch(_ fetchRequest: FetchRequest) throws -> [ModelInstance] {
        try self.fetchObjects(fetchRequest)
            .map { try ModelInstance(managedObject: $0) }
    }
    
    public func count(_ fetchRequest: FetchRequest) throws -> UInt {
        return UInt(try self.count(for: fetchRequest.toFoundation()))
    }
    
    public func insert(_ value: ModelInstance) throws {
        guard let model = self.persistentStoreCoordinator?.managedObjectModel else {
            assertionFailure("Missing model")
            throw CocoaError(.coreData)
        }
        try insert(value, model: model)
    }
    
    public func delete(_ entity: EntityName, for id: ObjectID) throws {
        guard let model = self.persistentStoreCoordinator?.managedObjectModel else {
            assertionFailure("Missing model")
            throw CocoaError(.coreData)
        }
        guard try delete(entity, for: id, model: model) else {
            assertionFailure("Object not found for \(id)")
            throw CocoaError(.coreData)
        }
    }
}

internal extension NSManagedObjectContext {
    
    func fetch(_ entity: EntityName, for id: ObjectID, model: NSManagedObjectModel) throws -> ModelInstance? {
        try self.find(entity, for: id, in: model)
            .flatMap { try ModelInstance(managedObject: $0) }
    }
    
    func fetchObjects(_ fetchRequest: FetchRequest) throws -> [NSManagedObject] {
        return try self.fetch(fetchRequest.toFoundation())
    }
    
    @discardableResult
    func delete(_ entity: EntityName, for id: ObjectID, model: NSManagedObjectModel) throws -> Bool {
        guard let managedObject = try self.find(entity, for: id, in: model) else {
            return false
        }
        self.delete(managedObject)
        return true
    }
    
    func create(
        _ entityName: EntityName,
        for id: ObjectID,
        in model: NSManagedObjectModel
    ) throws -> NSManagedObject {
        let entity = try model[entityName]
        let managedObject = NSManagedObject(entity: entity, insertInto: self)
        managedObject.setValue(id.rawValue, forKey: NSManagedObject.BuiltInProperty.id.rawValue)
        return managedObject
    }
    
    func find(
        _ entityName: EntityName,
        for id: ObjectID,
        in model: NSManagedObjectModel
    ) throws -> NSManagedObject? {
        let entity = try model[entityName]
        // TODO: 
        return nil
    }
    
    func insert(
        _ value: ModelInstance,
        model: NSManagedObjectModel
    ) throws {
        // find or create
        let managedObject = try find(value.entity, for: value.id, in: model) ?? create(value.entity, for: value.id, in: model)
        // apply attributes
        for (key, value) in value.attributes {
            managedObject.setAttribute(value, for: key)
        }
        // apply relationships
        for (key, value) in value.relationships {
            try managedObject.setRelationship(value, for: key, in: self)
        }
    }
}

#endif
