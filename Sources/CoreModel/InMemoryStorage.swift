//
//  InMemoryStorage.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/22/26.
//  Copyright © 2026 PureSwift. All rights reserved.
//

#if !hasFeature(Embedded)
import Foundation
#endif

/// Shared in-memory backing store.
///
/// Holds the objects and registered functions for an ``InMemoryModelStorage`` and,
/// optionally, one or more ``InMemoryViewContext`` values. Because the backing is a
/// reference type, a store and a view context that share the same instance observe
/// the exact same data.
///
/// The type is thread-safe: all access is serialized so the actor-isolated
/// ``InMemoryModelStorage`` and the main-actor ``InMemoryViewContext`` can operate
/// on the same instance concurrently. Under Embedded Swift, where the view context is
/// unavailable, the backing is only ever touched from within its owning actor and the
/// lock is elided.
final class InMemoryStorage {

    /// The schema entities are validated against.
    let model: Model

    private var objects = [EntityName: [ObjectID: ModelData]]()

    private var functions = [String: DatabaseFunction]()

    #if !hasFeature(Embedded)
    private let lock = NSLock()
    #endif

    init(model: Model) {
        self.model = model
    }

    private func withLock<T, E>(_ body: () throws(E) -> T) throws(E) -> T where E: Error {
        #if !hasFeature(Embedded)
        lock.lock()
        defer { lock.unlock() }
        #endif
        return try body()
    }

    func fetch(_ entity: EntityName, for id: ObjectID) throws(CoreModelError) -> ModelData? {
        try withLock { () throws(CoreModelError) in
            try validate(entity)
            return objects[entity]?[id]
        }
    }

    func fetch(_ fetchRequest: FetchRequest) throws(CoreModelError) -> [ModelData] {
        try withLock { () throws(CoreModelError) in
            try validate(fetchRequest.entity)
            let values = objects[fetchRequest.entity].map { Array($0.values) } ?? []
            return fetchRequest.evaluate(values, functions: functions)
        }
    }

    func fetchID(_ fetchRequest: FetchRequest) throws(CoreModelError) -> [ObjectID] {
        try fetch(fetchRequest).map { $0.id }
    }

    func count(_ fetchRequest: FetchRequest) throws(CoreModelError) -> UInt {
        try UInt(fetch(fetchRequest).count)
    }

    func insert(_ value: ModelData) throws(CoreModelError) {
        try withLock { () throws(CoreModelError) in
            try validate(value.entity)
            objects[value.entity, default: [:]][value.id] = value
        }
    }

    func insert(_ values: [ModelData]) throws(CoreModelError) {
        for value in values {
            try insert(value)
        }
    }

    func delete(_ entity: EntityName, for id: ObjectID) throws(CoreModelError) {
        try withLock { () throws(CoreModelError) in
            try validate(entity)
            objects[entity]?[id] = nil
        }
    }

    func delete(_ entity: EntityName, for ids: [ObjectID]) throws(CoreModelError) {
        try withLock { () throws(CoreModelError) in
            try validate(entity)
            for id in ids {
                objects[entity]?[id] = nil
            }
        }
    }

    func register(function: DatabaseFunction) {
        withLock {
            functions[function.name] = function
        }
    }

    private func validate(_ entity: EntityName) throws(CoreModelError) {
        guard model[entity] != nil else {
            throw CoreModelError.invalidEntity(entity)
        }
    }
}

// - Note: Safe because every access is serialized through `withLock` (non-Embedded)
//   or confined to the owning actor (Embedded).
extension InMemoryStorage: @unchecked Sendable {}
