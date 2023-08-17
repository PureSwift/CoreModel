//
//  Store.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/22/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import Predicate

/// CoreModel Store Protocol
public protocol ModelStorage: AnyObject {
    
    /// Fetch managed object.
    func fetch(_ entity: EntityName, for id: ObjectID) async throws -> ModelData?
    
    /// Fetch managed objects.
    func fetch(_ fetchRequest: FetchRequest) async throws -> [ModelData]
    
    /// Fetch and return result count.
    func count(_ fetchRequest: FetchRequest) async throws -> UInt
    
    /// Create or edit a managed object.
    func insert(_ value: ModelData) async throws
    
    /// Delete the specified managed object. 
    func delete(_ entity: EntityName, for id: ObjectID) async throws
}

public extension ModelStorage {
    
    func count(_ fetchRequest: FetchRequest) async throws -> UInt {
        return try await UInt(fetch(fetchRequest).count)
    }
}

// MARK: - ModelData

/// CoreModel Object Instance
public struct ModelData: Equatable, Hashable, Identifiable, Codable {
    
    public let entity: EntityName
    
    public let id: ObjectID
    
    public var attributes: [PropertyKey: AttributeValue]
    
    public var relationships: [PropertyKey: RelationshipValue]
    
    public init(
        entity: EntityName,
        id: ObjectID,
        attributes: [PropertyKey : AttributeValue] = [:],
        relationships: [PropertyKey : RelationshipValue] = [:]
    ) {
        self.entity = entity
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }
}

// MARK: - ModelStorage Codable Extensions

public extension ModelStorage {
    
    /// Fetch managed object.
    func fetch<T>(_ entity: T.Type, for id: ObjectID) async throws -> T? where T: Entity {
        guard let model = try await fetch(T.entityName, for: id) else {
            return nil
        }
        return try T.init(from: model)
    }
    
    /// Fetch managed objects.
    func fetch<T>(
        _ entity: T.Type,
        sortDescriptors: [FetchRequest.SortDescriptor] = [],
        predicate: Predicate? = nil,
        fetchLimit: Int = 0,
        fetchOffset: Int = 0
    ) async throws -> [ModelData] where T: Entity {
        let fetchRequest = FetchRequest(
            entity: T.entityName,
            sortDescriptors: sortDescriptors,
            predicate: predicate,
            fetchLimit: fetchLimit,
            fetchOffset: fetchOffset
        )
        return try await fetch(fetchRequest)
    }
    
    /// Fetch and return result count.
    func count<T>(
        _ entity: T.Type,
        sortDescriptors: [FetchRequest.SortDescriptor] = [],
        predicate: Predicate? = nil,
        fetchLimit: Int = 0,
        fetchOffset: Int = 0
    ) async throws -> UInt where T: Entity {
        let fetchRequest = FetchRequest(
            entity: T.entityName,
            sortDescriptors: sortDescriptors,
            predicate: predicate,
            fetchLimit: fetchLimit,
            fetchOffset: fetchOffset
        )
        return try await count(fetchRequest)
    }
    
    /// Create or edit a managed object.
    func insert<T>(_ value: T) async throws where T: Entity, T: Encodable {
        let model = value.encode()
        try await insert(model)
    }
    
    /// Delete the specified managed object.
    func delete<T>(_ entity: T.Type, for id: ObjectID) async throws where T: Entity {
        try await delete(T.entityName, for: id)
    }
}
