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
    
    public func fetch(_ entity: EntityName, for id: ObjectID) async throws -> ModelInstance? {
        let model = self.managedObjectModel
        return try await performBackgroundTask { context in
            guard let managedObject = try context.find(entity, for: id, in: model) else {
                return nil
            }
            return try ModelInstance(managedObject: managedObject)
        }
    }
    
    public func fetch(_ fetchRequest: FetchRequest) async throws -> [ModelInstance] {
        try await performBackgroundTask { context in
            try context.fetch(fetchRequest)
        }
    }
    
    public func count(_ fetchRequest: FetchRequest) async throws -> UInt {
        try await performBackgroundTask { context in
            try context.count(fetchRequest)
        }
    }
    
    public func insert(_ value: ModelInstance) async throws {
        let model = self.managedObjectModel
        try await performBackgroundTask { context in
            try context.insert(value, model: model)
        }
    }
    
    public func delete(_ entity: EntityName, for id: ObjectID) async throws {
        let model = self.managedObjectModel
        try await performBackgroundTask { context in
            guard try context.delete(entity, for: id, model: model) else {
                assertionFailure("Object not found for \(id)")
                throw CocoaError(.coreData)
            }
        }
    }
}
#endif
