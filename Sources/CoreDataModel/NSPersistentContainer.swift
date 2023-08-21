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

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
public extension NSPersistentContainer {
    
    func loadPersistentStores() -> AsyncThrowingStream<NSPersistentStoreDescription, Error> {
        assert(self.persistentStoreDescriptions.isEmpty == false)
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
}

#endif
