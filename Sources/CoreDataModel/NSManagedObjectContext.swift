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

extension NSManagedObjectContext: ModelStorage {
    
    public func fetch(_ entity: EntityName, for id: ObjectID) throws -> ModelData? {
        try self.find(entity, for: id)
            .flatMap { try ModelData(managedObject: $0) }
    }
    
    public func fetch(_ fetchRequest: FetchRequest) throws -> [ModelData] {
        try self.fetchObjects(fetchRequest)
            .map { try ModelData(managedObject: $0) }
    }
    
    public func count(_ fetchRequest: FetchRequest) throws -> UInt {
        return UInt(try self.count(for: fetchRequest.toFoundation()))
    }
    
    public func insert(_ value: ModelData) throws {
        guard let model = self.persistentStoreCoordinator?.managedObjectModel else {
            assertionFailure("Missing model")
            throw CocoaError(.coreData)
        }
        try insert(value, model: model)
    }
    
    public func delete(_ entity: EntityName, for id: ObjectID) throws {
        guard let managedObject = try self.find(entity, for: id) else {
            assertionFailure("Object not found for \(id)")
            throw CocoaError(.coreData)
        }
        self.delete(managedObject)
    }
}

internal extension NSManagedObjectContext {
    
    func fetchObjects(_ fetchRequest: FetchRequest) throws -> [NSManagedObject] {
        return try self.fetch(fetchRequest.toFoundation())
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
        for id: ObjectID
    ) throws -> NSManagedObject? {
        let fetchRequest = FetchRequest(
            entity: entityName,
            predicate: NSManagedObject.BuiltInProperty.id.rawValue == id.rawValue,
            fetchLimit: 1
        )
        return try fetchObjects(fetchRequest).first
    }
    
    func insert(
        _ value: ModelData,
        model: NSManagedObjectModel
    ) throws {
        // find or create
        let managedObject = try find(value.entity, for: value.id) ?? create(value.entity, for: value.id, in: model)
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
