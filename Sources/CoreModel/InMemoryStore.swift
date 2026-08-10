//
//  InMemoryStore.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/21/26.
//  Copyright © 2026 PureSwift. All rights reserved.
//

// - Note: Requires the `_Concurrency` runtime (an `actor`). Embedded targets
//   without a concurrency runtime (e.g. bare-metal ARM) use the synchronous
//   ``InMemoryStorage`` backing directly instead.
#if canImport(_Concurrency)

/// CoreModel In-Memory Store
///
/// A ``ModelStorage`` backend that keeps all objects in memory,
/// evaluating fetch requests with the pure Swift filtering engine.
/// Works on any platform, including Embedded Swift.
///
/// Useful for caching, previews, and testing, or as a lightweight store
/// on platforms without a persistence backend.
///
/// On platforms that support it, ``viewContext`` returns a synchronous,
/// main-actor ``InMemoryViewContext`` backed by the same data.
public actor InMemoryModelStorage {

    internal let backing: InMemoryStorage

    #if !hasFeature(Embedded)
    /// Cached view context shared by this store. Only ever accessed from the main actor.
    private nonisolated(unsafe) var _viewContext: InMemoryViewContext?
    #endif

    /// The schema this store validates entities against.
    public nonisolated var model: Model {
        backing.model
    }

    /// Initialize an empty store that validates entities against the given schema.
    public init(model: Model) {
        self.backing = InMemoryStorage(model: model)
    }

    /// Fetch managed object.
    public func fetch(_ entity: EntityName, for id: ObjectID) async throws(CoreModelError) -> ModelData? {
        try backing.fetch(entity, for: id)
    }

    /// Fetch managed objects.
    public func fetch(_ fetchRequest: FetchRequest) async throws(CoreModelError) -> [ModelData] {
        try backing.fetch(fetchRequest)
    }

    /// Fetch managed objects IDs.
    public func fetchID(_ fetchRequest: FetchRequest) async throws(CoreModelError) -> [ObjectID] {
        try backing.fetchID(fetchRequest)
    }

    /// Fetch and return result count.
    public func count(_ fetchRequest: FetchRequest) async throws(CoreModelError) -> UInt {
        try backing.count(fetchRequest)
    }

    /// Create or edit a managed object.
    public func insert(_ value: ModelData) async throws(CoreModelError) {
        try backing.insert(value)
    }

    /// Create or edit multiple managed objects.
    public func insert(_ values: [ModelData]) async throws(CoreModelError) {
        try backing.insert(values)
    }

    /// Delete the specified managed object.
    public func delete(_ entity: EntityName, for id: ObjectID) async throws(CoreModelError) {
        try backing.delete(entity, for: id)
    }

    /// Delete the specified managed objects.
    public func delete(_ entity: EntityName, for ids: [ObjectID]) async throws(CoreModelError) {
        try backing.delete(entity, for: ids)
    }

    /// Register a custom function so it can be invoked from a predicate or sort descriptor.
    public func register(function: DatabaseFunction) async throws(CoreModelError) {
        backing.register(function: function)
    }
}

// MARK: - ViewContext

#if !hasFeature(Embedded)
public extension InMemoryModelStorage {

    /// A synchronous, main-actor view context backed by the same data as this store.
    ///
    /// The same instance is returned on every access. Objects inserted or deleted
    /// through the store are visible to the view context, and vice versa, because
    /// both share the same in-memory backing.
    @MainActor var viewContext: InMemoryViewContext {
        if let existing = _viewContext {
            return existing
        }
        let context = InMemoryViewContext(backing: backing)
        _viewContext = context
        return context
    }
}
#endif

// MARK: - ModelStorage

#if !hasFeature(Embedded)
// - Note: Unavailable under Embedded Swift — the protocol's untyped-`throws`
//   requirements cannot be witnessed there, since converting the concrete
//   `CoreModelError` to `any Error` is disallowed (`#EmbeddedRestrictions`).
//   Embedded consumers call the store's methods directly; they provide the
//   same API with typed throws.
extension InMemoryModelStorage: ModelStorage {}
#endif

#endif // canImport(_Concurrency)
