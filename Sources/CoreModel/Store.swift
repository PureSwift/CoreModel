//
//  Store.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/22/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

/// CoreModel Store Protocol
public protocol ModelStorage: AnyObject, Sendable {
    
    /// Fetch managed object.
    func fetch(_ entity: EntityName, for id: ObjectID) async throws -> ModelData?
    
    /// Fetch managed objects.
    func fetch(_ fetchRequest: FetchRequest) async throws -> [ModelData]
    
    /// Fetch managed objects IDs.
    func fetchID(_ fetchRequest: FetchRequest) async throws -> [ObjectID]
    
    /// Fetch and return result count.
    func count(_ fetchRequest: FetchRequest) async throws -> UInt
    
    /// Create or edit a managed object.
    func insert(_ value: ModelData) async throws
    
    /// Create or edit multiple managed objects.
    func insert(_ values: [ModelData]) async throws
    
    /// Delete the specified managed object. 
    func delete(_ entity: EntityName, for id: ObjectID) async throws
    
    /// Delete the specified managed objects.
    func delete(_ entity: EntityName, for ids: [ObjectID]) async throws
}

#if !hasFeature(Embedded)
// - Note: Unavailable under Embedded Swift (a compiler bug in SILGen crashes on
//   an `async` default protocol-extension method calling another `async`
//   protocol requirement through `Self`, e.g. https://github.com/swiftlang/swift/issues/78811
//   and related embedded-async SILGen issues). Embedded conformers must
//   implement `count(_:)` and `insert(_:)` themselves.
public extension ModelStorage {

    func count(_ fetchRequest: FetchRequest) async throws -> UInt {
        return try await UInt(fetch(fetchRequest).count)
    }

    func insert(_ values: [ModelData]) async throws {
        for model in values {
            try await insert(model)
        }
    }
}
#endif

#if !hasFeature(Embedded)
@MainActor
public protocol ViewContext {
    
    /// Fetch managed object.
    func fetch(_ entity: EntityName, for id: ObjectID) throws -> ModelData?
    
    /// Fetch managed objects.
    func fetch(_ fetchRequest: FetchRequest) throws -> [ModelData]
    
    /// Fetch managed objects IDs.
    func fetchID(_ fetchRequest: FetchRequest) throws -> [ObjectID]
    
    /// Fetch and return result count.
    func count(_ fetchRequest: FetchRequest) throws -> UInt
}
#endif

// MARK: - ModelData

/// CoreModel Object Instance
public struct ModelData: Equatable, Hashable, Identifiable, Sendable {

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

// MARK: - Codable

#if !hasFeature(Embedded)
extension ModelData: Codable {}
#endif

// MARK: - ModelStorage Codable Extensions

#if !hasFeature(Embedded)
// - Note: Unavailable under Embedded Swift (a compiler bug in SILGen crashes on
//   `async` default protocol-extension methods that call another `async`
//   protocol requirement through `Self`). Embedded consumers should call the
//   `ModelStorage` protocol requirements directly with `ModelData`/`ObjectID`
//   and use `Entity.init(from:)`/`encode()` themselves.
public extension ModelStorage {

    /// Fetch managed object.
    func fetch<T>(_ entity: T.Type, for id: T.ID) async throws -> T? where T: Entity {
        let objectID = ObjectID(rawValue: id.description)
        guard let model = try await fetch(T.entityName, for: objectID) else {
            return nil
        }
        return try T.init(from: model)
    }
    
    /// Fetch managed objects.
    func fetch<T>(
        _ entity: T.Type,
        sortDescriptors: [FetchRequest.SortDescriptor] = [],
        predicate: FetchRequest.Predicate? = nil,
        fetchLimit: Int = 0,
        fetchOffset: Int = 0
    ) async throws -> [T] where T: Entity {
        let fetchRequest = FetchRequest(
            entity: T.entityName,
            sortDescriptors: sortDescriptors,
            predicate: predicate,
            fetchLimit: fetchLimit,
            fetchOffset: fetchOffset
        )
        return try await fetch(fetchRequest)
            .map { try T.init(from: $0) }
    }
    
    /// Fetch and return result count.
    func count<T>(
        _ entity: T.Type,
        sortDescriptors: [FetchRequest.SortDescriptor] = [],
        predicate: FetchRequest.Predicate? = nil,
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
    func insert<T>(_ value: T) async throws where T: Entity {
        let model = try value.encode() // should never fail
        try await insert(model)
    }
    
    /// Delete the specified managed object.
    func delete<T>(_ entity: T.Type, for id: T.ID) async throws where T: Entity {
        let objectID = ObjectID(rawValue: id.description)
        try await delete(T.entityName, for: objectID)
    }
}
#endif

#if !hasFeature(Embedded)
public extension ViewContext {

    /// Fetch managed object.
    func fetch<T>(_ entity: T.Type, for id: T.ID) throws -> T? where T: Entity {
        let objectID = ObjectID(rawValue: id.description)
        guard let model = try fetch(T.entityName, for: objectID) else {
            return nil
        }
        return try T.init(from: model)
    }
    
    /// Fetch managed objects.
    func fetch<T>(
        _ entity: T.Type,
        sortDescriptors: [FetchRequest.SortDescriptor] = [],
        predicate: FetchRequest.Predicate? = nil,
        fetchLimit: Int = 0,
        fetchOffset: Int = 0
    ) throws -> [T] where T: Entity {
        let fetchRequest = FetchRequest(
            entity: T.entityName,
            sortDescriptors: sortDescriptors,
            predicate: predicate,
            fetchLimit: fetchLimit,
            fetchOffset: fetchOffset
        )
        return try fetch(fetchRequest)
            .map { try T.init(from: $0) }
    }
    
    /// Fetch and return result count.
    func count<T>(
        _ entity: T.Type,
        sortDescriptors: [FetchRequest.SortDescriptor] = [],
        predicate: FetchRequest.Predicate? = nil,
        fetchLimit: Int = 0,
        fetchOffset: Int = 0
    ) throws -> UInt where T: Entity {
        let fetchRequest = FetchRequest(
            entity: T.entityName,
            sortDescriptors: sortDescriptors,
            predicate: predicate,
            fetchLimit: fetchLimit,
            fetchOffset: fetchOffset
        )
        return try count(fetchRequest)
    }
}
#endif
