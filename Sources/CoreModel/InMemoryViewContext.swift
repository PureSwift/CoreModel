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
/// Useful for SwiftUI previews, unit tests, and lightweight main-thread caches
/// where the `async` ``InMemoryModelStorage`` would be inconvenient.
@MainActor
public final class InMemoryViewContext {

    /// The schema this context validates entities against.
    public let model: Model

    private var storage = [EntityName: [ObjectID: ModelData]]()

    private var functions = [String: DatabaseFunction]()

    /// Initialize an empty context that validates entities against the given schema.
    public init(model: Model) {
        self.model = model
    }

    /// Fetch managed object.
    public func fetch(_ entity: EntityName, for id: ObjectID) throws(CoreModelError) -> ModelData? {
        try validate(entity)
        return storage[entity]?[id]
    }

    /// Fetch managed objects.
    public func fetch(_ fetchRequest: FetchRequest) throws(CoreModelError) -> [ModelData] {
        try validate(fetchRequest.entity)
        let objects = storage[fetchRequest.entity].map { Array($0.values) } ?? []
        return fetchRequest.evaluate(objects, functions: functions)
    }

    /// Fetch managed objects IDs.
    public func fetchID(_ fetchRequest: FetchRequest) throws(CoreModelError) -> [ObjectID] {
        try fetch(fetchRequest).map { $0.id }
    }

    /// Fetch and return result count.
    public func count(_ fetchRequest: FetchRequest) throws(CoreModelError) -> UInt {
        try UInt(fetch(fetchRequest).count)
    }

    /// Create or edit a managed object.
    public func insert(_ value: ModelData) throws(CoreModelError) {
        try validate(value.entity)
        storage[value.entity, default: [:]][value.id] = value
    }

    /// Create or edit multiple managed objects.
    public func insert(_ values: [ModelData]) throws(CoreModelError) {
        for value in values {
            try insert(value)
        }
    }

    /// Delete the specified managed object.
    public func delete(_ entity: EntityName, for id: ObjectID) throws(CoreModelError) {
        try validate(entity)
        storage[entity]?[id] = nil
    }

    /// Delete the specified managed objects.
    public func delete(_ entity: EntityName, for ids: [ObjectID]) throws(CoreModelError) {
        try validate(entity)
        for id in ids {
            storage[entity]?[id] = nil
        }
    }

    /// Register a custom function so it can be invoked from a predicate or sort descriptor.
    public func register(function: DatabaseFunction) {
        functions[function.name] = function
    }

    private func validate(_ entity: EntityName) throws(CoreModelError) {
        guard model[entity] != nil else {
            throw CoreModelError.invalidEntity(entity)
        }
    }
}

// MARK: - ViewContext

extension InMemoryViewContext: ViewContext {}

#endif
