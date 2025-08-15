//
//  NSPersistentContainer.swift
//  
//
//  Created by Alsey Coleman Miller on 8/17/23.
//

#if canImport(CoreData)
import Foundation
import CoreData
import CoreModel

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
extension NSPersistentContainer: ModelStorage {
    
    public func fetch(_ entity: EntityName, for id: ObjectID) async throws -> ModelData? {
        return try await performBackgroundTask { context in
            try context.fetch(entity, for: id)
        }
    }
    
    public func fetch(_ fetchRequest: FetchRequest) async throws -> [ModelData] {
        try await performBackgroundTask { context in
            try context.fetch(fetchRequest)
        }
    }
    
    public func count(_ fetchRequest: FetchRequest) async throws -> UInt {
        try await performBackgroundTask { context in
            try context.count(fetchRequest)
        }
    }
    
    public func insert(_ value: ModelData) async throws {
        let model = self.managedObjectModel
        try await performBackgroundTask { context in
            try context.insert(value, model: model)
        }
    }
    
    public func insert(_ values: [ModelData]) async throws {
        let model = self.managedObjectModel
        try await performBackgroundTask { context in
            try context.insert(values, model: model)
        }
    }
    
    public func delete(_ entity: EntityName, for id: ObjectID) async throws {
        try await performBackgroundTask { context in
            try context.delete(entity, for: id)
        }
    }
    
    public func fetchID(_ fetchRequest: FetchRequest) async throws -> [ObjectID] {
        try await performBackgroundTask { context in
            try context.fetchID(fetchRequest)
        }
    }
}

// MARK: - PersistentContainerStorage

/// Concurrency safe persistent storage
///
/// Write will happen on a single isolation context using a single background managed object context
@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
public actor PersistentContainerStorage: ModelStorage, ObservableObject {
    
    // MARK: Initialization
    
    public init(
        name: String,
        model: Model,
        storeDescriptions: [NSPersistentStoreDescription] = []
    ) {
        let managedObjectModel = NSManagedObjectModel(model: model)
        let persistentContainer = NSPersistentContainer(
            name: name,
            managedObjectModel: managedObjectModel
        )
        self.persistentContainer = persistentContainer
        // use custom store descriptions
        if storeDescriptions.isEmpty == false {
            persistentContainer.persistentStoreDescriptions = storeDescriptions
        }
    }
    
    // MARK: Properties
    
    internal let persistentContainer: NSPersistentContainer
    
    internal nonisolated(unsafe) var _viewContext: ManagedObjectViewContext?
    
    @MainActor
    public var viewContext: ManagedObjectViewContext {
        get throws {
            // lazily load stores
            try loadStores()
            // lazily load view context
            if let viewConext = _viewContext {
                return viewConext
            } else {
                let viewContext = ManagedObjectViewContext(persistentContainer: persistentContainer)
                _viewContext = viewContext
                return viewContext
            }
        }
    }
    
    private nonisolated(unsafe) var state: State = .notLoaded
    
    private lazy var backgroundContext = persistentContainer.newBackgroundContext()
    
    // MARK: Methods
    
    public func fetch(_ entity: EntityName, for id: ObjectID) async throws -> ModelData? {
        return try await performBackgroundTask { (context, model) in
            try context.fetch(entity, for: id)
        }
    }
    
    public func fetch(_ fetchRequest: FetchRequest) async throws -> [ModelData] {
        try await performBackgroundTask { (context, model) in
            try context.fetch(fetchRequest)
        }
    }
    
    public func fetchID(_ fetchRequest: FetchRequest) async throws -> [ObjectID] {
        return try await performBackgroundTask { (context, model) in
            try context.fetchID(fetchRequest)
        }
    }
    
    public func count(_ fetchRequest: FetchRequest) async throws -> UInt {
        try await performBackgroundTask { (context, model) in
            try context.count(fetchRequest)
        }
    }
    
    public func insert(_ value: ModelData) async throws {
        defer { objectWillChange.send() }
        try await performBackgroundTask { (context, model) in
            try context.insert(value, model: model)
        }
    }
    
    public func insert(_ values: [ModelData]) async throws {
        defer { objectWillChange.send() }
        try await performBackgroundTask { (context, model) in
            try context.insert(values, model: model)
        }
    }
    
    public func delete(_ entity: EntityName, for id: ObjectID) async throws {
        defer { objectWillChange.send() }
        try await performBackgroundTask { (context, model) in
            try context.delete(entity, for: id)
        }
    }
    
    private func performBackgroundTask<T>(
        schedule: NSManagedObjectContext.ScheduledTaskType = .immediate,
        _ task: @escaping (NSManagedObjectContext, NSManagedObjectModel) throws -> T
    ) async throws -> T {
        try await loadStores()
        let model = persistentContainer.managedObjectModel
        let context = backgroundContext
        return try await context.perform(schedule: schedule) {
            try task(context, model)
        }
    }
    
    @MainActor
    private func loadStores() async throws {
        // lazily load stores
        guard state == .notLoaded else {
            // already loaded or loading
            return
        }
        state = .loading
        do {
            for try await store in persistentContainer.loadPersistentStores() {
                // continue
                _ = store
            }
        }
        catch {
            state = .notLoaded
            throw error
        }
        state = .loaded
    }
    
    private nonisolated func loadStores() throws {
        // lazily load stores
        guard state == .notLoaded else {
            // already loaded or loading
            return
        }
        state = .loading
        do {
            try persistentContainer.syncLoadPersistentStores()
        }
        catch {
            return
        }
        state = .loaded
    }
}

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
internal extension PersistentContainerStorage {
    
    enum State: Equatable, Hashable, Sendable {
        
        case notLoaded
        case loading
        case loaded
    }
}

// MARK: - Extensions

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
public extension NSPersistentContainer {
    
    func loadPersistentStores() -> AsyncThrowingStream<NSPersistentStoreDescription, Error> {
        assert(self.persistentStoreDescriptions.isEmpty == false)
        for store in persistentStoreDescriptions {
            store.shouldAddStoreAsynchronously = true
        }
        return AsyncThrowingStream<NSPersistentStoreDescription, Error>.init(NSPersistentStoreDescription.self, bufferingPolicy: .unbounded, { continuation in
            self.loadPersistentStores { [unowned self] (description, error) in
                continuation.yield(description)
                if let error = error {
                    continuation.finish(throwing: error)
                    return
                }
                if description == self.persistentStoreDescriptions.last {
                    continuation.finish()
                }
            }
        })
    }
    
    func syncLoadPersistentStores() throws {
        assert(self.persistentStoreDescriptions.isEmpty == false)
        for store in persistentStoreDescriptions {
            store.shouldAddStoreAsynchronously = false
        }
        var caughtError: Error?
        self.loadPersistentStores { (description, error) in
            if let error {
                caughtError = error
            }
        }
        if let error = caughtError {
            throw error
        }
    }
}

#endif
