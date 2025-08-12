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

extension NSManagedObjectContext: ModelStorage, ViewContext {
    
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
    
    public func insert(_ values: [ModelData]) throws {
        guard let model = self.persistentStoreCoordinator?.managedObjectModel else {
            assertionFailure("Missing model")
            throw CocoaError(.coreData)
        }
        try insert(values, model: model)
    }
    
    public func delete(_ entity: EntityName, for id: ObjectID) throws {
        guard let managedObject = try self.find(entity, for: id) else {
            assertionFailure("Object not found for \(id)")
            throw CocoaError(.coreData)
        }
        self.delete(managedObject)
    }
    
    public func fetchID(_ fetchRequest: FetchRequest) throws -> [ObjectID] {
        let fetch = fetchRequest.toFoundation()
        fetch.propertiesToFetch = [NSManagedObject.BuiltInProperty.id.rawValue]
        fetch.returnsObjectsAsFaults = false
        return try self.fetch(fetchRequest.toFoundation()).map { try $0.modelObjectID }
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
        ).toFoundation(NSManagedObjectID.self)
        assert(fetchRequest.resultType == .managedObjectIDResultType)
        let objectIDs = try self.fetch(fetchRequest)
        return objectIDs.first.flatMap { self.object(with: $0) }
    }
    
    func insert(
        _ value: ModelData,
        model: NSManagedObjectModel,
        shouldSave: Bool = true
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
        if shouldSave {
            try self.save()
        }
    }
    
    func insert(
        _ values: [ModelData],
        model: NSManagedObjectModel
    ) throws {
        for value in values {
            try insert(value, model: model, shouldSave: false)
        }
        try self.save()
    }
}

#endif
