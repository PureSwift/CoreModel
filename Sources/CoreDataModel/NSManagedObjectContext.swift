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
        context.automaticallyMergesChangesFromParent = true
        context.stalenessInterval = 0
        context.undoManager = nil
        assert(context.concurrencyType == .mainQueueConcurrencyType)
        setupNotificationObservers()
    }
    
    public init(persistentContainer: NSPersistentContainer) {
        self.context = persistentContainer.viewContext
        context.automaticallyMergesChangesFromParent = true
        context.stalenessInterval = 0
        context.undoManager = nil
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
        for id: ObjectID,
        includesPropertyValues: Bool = true
    ) throws -> NSManagedObject? {
        let fetchRequest = FetchRequest(
            entity: entityName,
            predicate: NSManagedObject.BuiltInProperty.id.rawValue == id.rawValue,
            fetchLimit: 1
        ).toFoundation(NSManagedObject.self)
        fetchRequest.includesPropertyValues = includesPropertyValues
        assert(fetchRequest.resultType == .managedObjectResultType)
        return try self.fetch(fetchRequest).first
    }
    
    func insert(
        _ value: ModelData,
        model: NSManagedObjectModel,
        shouldSave: Bool = true
    ) throws {
        // find or create
        let managedObject = try find(value.entity, for: value.id, includesPropertyValues: false) ?? create(value.entity, for: value.id, in: model)
        try managedObject.setValues(for: value, in: self)
        if shouldSave {
            try self.save()
        }
    }
    
    func insert(
        _ values: [ModelData],
        model: NSManagedObjectModel
    ) throws {
        guard values.isEmpty == false else { return }
        // Prefetch every object referenced by the batch (inserted values and their
        // relationship targets) with one fetch request per entity. Per-object
        // find-or-create degrades quadratically as pending inserts accumulate,
        // because each fetch request evaluates its predicate against all unsaved
        // objects in the context.
        var cache = try prefetch(for: values, model: model)
        // find or create the inserted objects first so relationships between
        // values in the same batch resolve regardless of their order
        var managedObjects = [NSManagedObject]()
        managedObjects.reserveCapacity(values.count)
        for value in values {
            let managedObject: NSManagedObject
            if let cached = cache[value.entity]?[value.id] {
                managedObject = cached
            } else {
                // the prefetch covered every value identifier, so a cache miss
                // means the object does not exist yet
                managedObject = try create(value.entity, for: value.id, in: model, cache: &cache)
            }
            managedObjects.append(managedObject)
        }
        // apply attributes and relationships
        for (index, value) in values.enumerated() {
            try managedObjects[index].setValues(for: value, in: self, cache: &cache)
        }
        try self.save()
    }
}

internal extension NSManagedObjectContext {

    /// Realized managed objects by entity and identifier, used to avoid per-object
    /// fetch requests during batch inserts.
    typealias ManagedObjectCache = [EntityName: [ObjectID: NSManagedObject]]

    /// Fetch the existing managed objects referenced by the given values
    /// (both inserted objects and their relationship targets) with a single
    /// fetch request per entity.
    func prefetch(
        for values: [ModelData],
        model: NSManagedObjectModel
    ) throws -> ManagedObjectCache {
        // collect identifiers by entity
        var idsByEntity = [EntityName: Set<ObjectID>]()
        for value in values {
            idsByEntity[value.entity, default: []].insert(value.id)
            guard value.relationships.isEmpty == false else { continue }
            let relationshipsByName = try model[value.entity].relationshipsByName
            for (key, relationship) in value.relationships {
                guard let destinationEntity = relationshipsByName[key.rawValue]?.destinationEntity?.name.map({ EntityName(rawValue: $0) }) else {
                    continue
                }
                switch relationship {
                case .null:
                    continue
                case let .toOne(id):
                    idsByEntity[destinationEntity, default: []].insert(id)
                case let .toMany(ids):
                    idsByEntity[destinationEntity, default: []].formUnion(ids)
                }
            }
        }
        // fetch existing objects with a single request per entity
        var cache = ManagedObjectCache(minimumCapacity: idsByEntity.count)
        for (entityName, ids) in idsByEntity {
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName.rawValue)
            fetchRequest.predicate = NSPredicate(
                format: "%K IN %@",
                NSManagedObject.BuiltInProperty.id.rawValue,
                ids.map { $0.rawValue }
            )
            fetchRequest.returnsObjectsAsFaults = false
            var entityCache = [ObjectID: NSManagedObject](minimumCapacity: ids.count)
            for managedObject in try self.fetch(fetchRequest) {
                entityCache[try managedObject.modelObjectID] = managedObject
            }
            cache[entityName] = entityCache
        }
        return cache
    }

    /// Find the managed object through the cache, falling back to a fetch request
    /// and caching the result.
    func find(
        _ entityName: EntityName,
        for id: ObjectID,
        cache: inout ManagedObjectCache
    ) throws -> NSManagedObject? {
        if let managedObject = cache[entityName]?[id] {
            return managedObject
        }
        guard let managedObject = try find(entityName, for: id, includesPropertyValues: false) else {
            return nil
        }
        cache[entityName, default: [:]][id] = managedObject
        return managedObject
    }

    /// Create the managed object and add it to the cache.
    func create(
        _ entityName: EntityName,
        for id: ObjectID,
        in model: NSManagedObjectModel,
        cache: inout ManagedObjectCache
    ) throws -> NSManagedObject {
        let managedObject = try create(entityName, for: id, in: model)
        cache[entityName, default: [:]][id] = managedObject
        return managedObject
    }
}

#endif
