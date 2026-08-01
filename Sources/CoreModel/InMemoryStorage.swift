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
/// on the same instance concurrently. Under Embedded Swift the lock is elided:
/// with a concurrency runtime the backing is only ever touched from within its
/// owning actor, and without one (e.g. bare-metal ARM, where ``ModelStorage``
/// itself is unavailable) this synchronous store is the storage API, used
/// directly from the single-threaded main loop.
public final class InMemoryStorage {

    /// The schema entities are validated against.
    public let model: Model

    private var objects = [EntityName: [ObjectID: ModelData]]()

    private var functions = [String: DatabaseFunction]()

    #if !hasFeature(Embedded)
    private let lock = NSLock()
    #endif

    public init(model: Model) {
        self.model = model
    }

    private func withLock<T, E>(_ body: () throws(E) -> T) throws(E) -> T where E: Error {
        #if !hasFeature(Embedded)
        lock.lock()
        defer { lock.unlock() }
        #endif
        return try body()
    }

    public func fetch(_ entity: EntityName, for id: ObjectID) throws(CoreModelError) -> ModelData? {
        try withLock { () throws(CoreModelError) in
            try validate(entity)
            return objects[entity]?[id].map { normalized(entity: entity, $0) }
        }
    }

    public func fetch(_ fetchRequest: FetchRequest) throws(CoreModelError) -> [ModelData] {
        try withLock { () throws(CoreModelError) in
            try validate(fetchRequest.entity)
            let values = (objects[fetchRequest.entity].map { Array($0.values) } ?? [])
                .map { normalized(entity: fetchRequest.entity, $0) }
            return fetchRequest.evaluate(values, functions: functions)
        }
    }

    /// Materializes every attribute and to-many relationship the schema declares, the way a
    /// SQL row or a Core Data managed object does automatically on read.
    ///
    /// A SQL column binds `NULL` for anything an `INSERT` doesn't provide, and a Core Data
    /// managed object always has a value (`nil` for an unset optional) for every attribute
    /// its model declares — a row is never partially formed on either backend. This store
    /// keeps only the keys `insert` was actually given, so an attribute nobody has ever
    /// explicitly set to `.null` (rather than simply never provided) previously decoded as
    /// `keyNotFound` instead of the absence it actually represents.
    ///
    /// To-many relationships get the same treatment along a different axis: neither backend
    /// stores a to-many value on the row that owns it in the first place. A one-to-many
    /// (whose inverse is a to-one foreign key, e.g. `WalletCard.user` → `User`) is answered
    /// by scanning the destination table for rows whose foreign key points back here, and a
    /// many-to-many (whose inverse is also to-many) by a join table either side can add a
    /// link to. A row whose to-many relationship key was never explicitly set — which
    /// includes every one-to-many, which is supposed to be entirely computed and never
    /// assigned — previously decoded as `keyNotFound` instead of the collection it actually
    /// has. To-one relationships are left alone: an absent required reference is a real data
    /// problem, not a default.
    private func normalized(entity: EntityName, _ value: ModelData) -> ModelData {
        guard let description = model[entity] else { return value }
        var value = value
        for attribute in description.attributes where value.attributes[attribute.id] == nil {
            value.attributes[attribute.id] = .null
        }
        for relationship in description.relationships where relationship.type == .toMany {
            guard let destination = model[relationship.destinationEntity],
                let inverse = destination.relationships.first(where: { $0.id == relationship.inverseRelationship })
            else {
                if value.relationships[relationship.id] == nil {
                    value.relationships[relationship.id] = .toMany([])
                }
                continue
            }
            let candidates = objects[relationship.destinationEntity].map { Array($0.values) } ?? []
            switch inverse.type {
            case .toOne:
                // One-to-many: always derived live from the destination rows' foreign key,
                // matching SQL/Core Data — this row never stores it itself.
                let derived = candidates
                    .filter { $0.relationships[inverse.id] == .toOne(value.id) }
                    .map { $0.id }
                value.relationships[relationship.id] = .toMany(derived)
            case .toMany:
                // Many-to-many: no join table here, so union whatever this row already
                // records with anything the destination rows record pointing back — a link
                // added from either side is visible from both.
                var ids = Set<ObjectID>()
                if case let .toMany(existing)? = value.relationships[relationship.id] {
                    ids.formUnion(existing)
                }
                for candidate in candidates {
                    if case let .toMany(backLinks)? = candidate.relationships[inverse.id],
                        backLinks.contains(value.id)
                    {
                        ids.insert(candidate.id)
                    }
                }
                value.relationships[relationship.id] = .toMany(Array(ids))
            }
        }
        return value
    }

    public func fetchID(_ fetchRequest: FetchRequest) throws(CoreModelError) -> [ObjectID] {
        try fetch(fetchRequest).map { $0.id }
    }

    public func count(_ fetchRequest: FetchRequest) throws(CoreModelError) -> UInt {
        try UInt(fetch(fetchRequest).count)
    }

    public func insert(_ value: ModelData) throws(CoreModelError) {
        try withLock { () throws(CoreModelError) in
            try validate(value.entity)
            // A key present in `value` overrides; a key the existing row already had that
            // `value` doesn't mention is preserved — the same "only touch the columns you
            // provided" semantics a SQL `ON CONFLICT DO UPDATE` or a Core Data managed object
            // gives for free. Without this, re-inserting a row from a batch that doesn't
            // touch every relationship (e.g. a site catalog refresh that never re-states
            // `parkingReservations`, which is written by an entirely separate sync) would
            // silently wipe those links instead of leaving them alone.
            if var existing = objects[value.entity]?[value.id] {
                // - Note: Explicit loops rather than `Dictionary.merge(_:uniquingKeysWith:)` —
                //   the closure-based overload does dynamic casting internally, which is
                //   disallowed under Embedded Swift.
                for (key, attribute) in value.attributes {
                    existing.attributes[key] = attribute
                }
                for (key, relationship) in value.relationships {
                    existing.relationships[key] = relationship
                }
                objects[value.entity, default: [:]][value.id] = existing
            } else {
                objects[value.entity, default: [:]][value.id] = value
            }
        }
    }

    public func insert(_ values: [ModelData]) throws(CoreModelError) {
        for value in values {
            try insert(value)
        }
    }

    public func delete(_ entity: EntityName, for id: ObjectID) throws(CoreModelError) {
        try withLock { () throws(CoreModelError) in
            try validate(entity)
            objects[entity]?[id] = nil
        }
    }

    public func delete(_ entity: EntityName, for ids: [ObjectID]) throws(CoreModelError) {
        try withLock { () throws(CoreModelError) in
            try validate(entity)
            for id in ids {
                objects[entity]?[id] = nil
            }
        }
    }

    public func register(function: DatabaseFunction) {
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
