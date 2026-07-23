//
//  InMemoryViewContext.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/22/26.
//  Copyright © 2026 PureSwift. All rights reserved.
//

#if !hasFeature(Embedded)
// - Note: Unavailable under Embedded Swift, since ``ViewContext`` itself relies
//   on `any Error` conversions that are disallowed there (`#EmbeddedRestrictions`).

/// CoreModel In-Memory View Context
///
/// A ``ViewContext`` backed entirely by memory, providing synchronous,
/// main-actor access to managed objects while evaluating fetch requests with the
/// pure Swift filtering engine.
///
/// A view context can be created standalone, or obtained from an
/// ``InMemoryModelStorage`` via ``InMemoryModelStorage/viewContext`` to read and
/// write the same underlying data as the store.
///
/// Useful for SwiftUI previews, unit tests, and lightweight main-thread caches
/// where the `async` ``InMemoryModelStorage`` would be inconvenient.
@MainActor
public final class InMemoryViewContext {

    internal let backing: InMemoryStorage

    /// The schema this context validates entities against.
    public var model: Model {
        backing.model
    }

    /// Initialize a view context that shares the given backing store.
    internal init(backing: InMemoryStorage) {
        self.backing = backing
    }

    /// Initialize an empty context that validates entities against the given schema.
    public init(model: Model) {
        self.backing = InMemoryStorage(model: model)
    }

    /// Fetch managed object.
    public func fetch(_ entity: EntityName, for id: ObjectID) throws(CoreModelError) -> ModelData? {
        try backing.fetch(entity, for: id)
    }

    /// Fetch managed objects.
    public func fetch(_ fetchRequest: FetchRequest) throws(CoreModelError) -> [ModelData] {
        try backing.fetch(fetchRequest)
    }

    /// Fetch managed objects IDs.
    public func fetchID(_ fetchRequest: FetchRequest) throws(CoreModelError) -> [ObjectID] {
        try backing.fetchID(fetchRequest)
    }

    /// Fetch and return result count.
    public func count(_ fetchRequest: FetchRequest) throws(CoreModelError) -> UInt {
        try backing.count(fetchRequest)
    }

    /// Create or edit a managed object.
    public func insert(_ value: ModelData) throws(CoreModelError) {
        try backing.insert(value)
    }

    /// Create or edit multiple managed objects.
    public func insert(_ values: [ModelData]) throws(CoreModelError) {
        try backing.insert(values)
    }

    /// Delete the specified managed object.
    public func delete(_ entity: EntityName, for id: ObjectID) throws(CoreModelError) {
        try backing.delete(entity, for: id)
    }

    /// Delete the specified managed objects.
    public func delete(_ entity: EntityName, for ids: [ObjectID]) throws(CoreModelError) {
        try backing.delete(entity, for: ids)
    }

    /// Register a custom function so it can be invoked from a predicate or sort descriptor.
    public func register(function: DatabaseFunction) {
        backing.register(function: function)
    }
}

// MARK: - ViewContext

extension InMemoryViewContext: ViewContext {}

#endif
