//
//  InMemoryStore.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/21/26.
//  Copyright © 2026 PureSwift. All rights reserved.
//

/// CoreModel In-Memory Store
///
/// A ``ModelStorage`` backend that keeps all objects in memory,
/// evaluating fetch requests with the pure Swift filtering engine.
/// Works on any platform, including Embedded Swift.
///
/// Useful for caching, previews, and testing, or as a lightweight store
/// on platforms without a persistence backend.
public actor InMemoryModelStorage {

    /// The schema this store validates entities against, if any.
    public let model: Model?

    private var storage = [EntityName: [ObjectID: ModelData]]()

    private var functions = [String: DatabaseFunction]()

    /// Initialize an empty store, optionally validating entities against a schema.
    public init(model: Model? = nil) {
        self.model = model
    }

    /// Fetch managed object.
    public func fetch(_ entity: EntityName, for id: ObjectID) async throws(CoreModelError) -> ModelData? {
        try validate(entity)
        return storage[entity]?[id]
    }

    /// Fetch managed objects.
    public func fetch(_ fetchRequest: FetchRequest) async throws(CoreModelError) -> [ModelData] {
        try validate(fetchRequest.entity)
        let objects = storage[fetchRequest.entity].map { Array($0.values) } ?? []
        return fetchRequest.evaluate(objects, functions: functions)
    }

    /// Fetch managed objects IDs.
    public func fetchID(_ fetchRequest: FetchRequest) async throws(CoreModelError) -> [ObjectID] {
        try await fetch(fetchRequest).map { $0.id }
    }

    /// Fetch and return result count.
    public func count(_ fetchRequest: FetchRequest) async throws(CoreModelError) -> UInt {
        try await UInt(fetch(fetchRequest).count)
    }

    /// Create or edit a managed object.
    public func insert(_ value: ModelData) async throws(CoreModelError) {
        try validate(value.entity)
        storage[value.entity, default: [:]][value.id] = value
    }

    /// Create or edit multiple managed objects.
    public func insert(_ values: [ModelData]) async throws(CoreModelError) {
        for value in values {
            try await insert(value)
        }
    }

    /// Delete the specified managed object.
    public func delete(_ entity: EntityName, for id: ObjectID) async throws(CoreModelError) {
        try validate(entity)
        storage[entity]?[id] = nil
    }

    /// Delete the specified managed objects.
    public func delete(_ entity: EntityName, for ids: [ObjectID]) async throws(CoreModelError) {
        try validate(entity)
        for id in ids {
            storage[entity]?[id] = nil
        }
    }

    /// Register a custom function so it can be invoked from a predicate or sort descriptor.
    public func register(function: DatabaseFunction) async throws(CoreModelError) {
        functions[function.name] = function
    }

    private func validate(_ entity: EntityName) throws(CoreModelError) {
        if let model, model[entity] == nil {
            throw CoreModelError.invalidEntity(entity)
        }
    }
}

// MARK: - ModelStorage

#if !hasFeature(Embedded)
// - Note: Unavailable under Embedded Swift — the protocol's untyped-`throws`
//   requirements cannot be witnessed there, since converting the concrete
//   `CoreModelError` to `any Error` is disallowed (`#EmbeddedRestrictions`).
//   Embedded consumers call the store's methods directly; they provide the
//   same API with typed throws.
extension InMemoryModelStorage: ModelStorage {}
#endif
