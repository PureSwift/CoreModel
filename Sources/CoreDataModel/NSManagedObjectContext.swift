//
//  NSManagedObjectContext.swift
//  CoreDataModel
//
//  Created by Alsey Coleman Miller on 11/4/18.
//

#if canImport(CoreData)
import Foundation
import Combine
import CoreData
import CoreModel

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
    
    public func insert(_ values: [ModelData]) throws {
        guard let model = self.persistentStoreCoordinator?.managedObjectModel else {
            assertionFailure("Missing model")
            throw CocoaError(.coreData)
        }
        try insert(values, model: model)
    }
    
    public func delete(_ entity: EntityName, for id: ObjectID) throws {
        try delete(entity, for: [id])
    }
    
    public func delete(_ entity: EntityName, for ids: [ObjectID]) throws {
        for id in ids {
        guard let managedObject = try self.find(entity, for: id) else {
                continue
            }
            self.delete(managedObject)
        }
        try self.save()
    }
    
    public func fetchID(_ fetchRequest: FetchRequest) throws -> [ObjectID] {
        let fetch = fetchRequest.toFoundation()
        fetch.propertiesToFetch = [NSManagedObject.BuiltInProperty.id.rawValue]
        fetch.returnsObjectsAsFaults = false
        return try self.fetch(fetchRequest.toFoundation()).map { try $0.modelObjectID }
    }
}

// MARK: - ManagedObjectViewContext

@MainActor
public final class ManagedObjectViewContext: ViewContext, ObservableObject {
    
    internal let context: NSManagedObjectContext
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(context: NSManagedObjectContext) {
        self.context = context
        assert(context.concurrencyType == .mainQueueConcurrencyType)
        setupNotificationObservers()
    }
    
    public init(persistentContainer: NSPersistentContainer) {
        self.context = persistentContainer.viewContext
        assert(context.concurrencyType == .mainQueueConcurrencyType)
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        // Observe object changes (insertions, deletions, updates)
        NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: context)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleContextDidChange(notification)
            }
            .store(in: &cancellables)
        
        // Observe saves
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: context)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleContextDidSave(notification)
            }
            .store(in: &cancellables)
    }
    
    private func handleContextDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        let hasInsertedObjects = (userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>)?.isEmpty == false
        let hasUpdatedObjects = (userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>)?.isEmpty == false
        let hasDeletedObjects = (userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>)?.isEmpty == false
        
        if hasInsertedObjects || hasUpdatedObjects || hasDeletedObjects {
            objectWillChange.send()
        }
    }
    
    private func handleContextDidSave(_ notification: Notification) {
        objectWillChange.send()
    }
    
    /// Fetch managed object.
    public func fetch(_ entity: EntityName, for id: ObjectID) throws -> ModelData? {
        try context.fetch(entity, for: id)
    }
    
    /// Fetch managed objects.
    public func fetch(_ fetchRequest: FetchRequest) throws -> [ModelData] {
        try context.fetch(fetchRequest)
    }
    
    /// Fetch managed objects IDs.
    public func fetchID(_ fetchRequest: FetchRequest) throws -> [ObjectID] {
        try context.fetchID(fetchRequest)
    }
    
    /// Fetch and return result count.
    public func count(_ fetchRequest: FetchRequest) throws -> UInt {
        try context.count(fetchRequest)
    }
}

// MARK: - Extensions

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
