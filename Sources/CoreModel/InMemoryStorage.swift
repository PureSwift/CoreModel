//
//  InMemoryStorage.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/22/26.
//  Copyright © 2026 PureSwift. All rights reserved.
//

/// Shared in-memory backing store.
///
/// Holds the objects and registered functions for an ``InMemoryModelStorage`` and,
/// optionally, one or more ``InMemoryViewContext`` values. Because the backing is a
/// reference type, a store and a view context that share the same instance observe
/// the exact same data.
///
/// The type is thread-safe: the mutable state lives behind a ``Locked`` (a `Mutex`
/// where the runtime has one, `NSLock` on older Darwin), so the sendable
/// ``InMemoryModelStorage`` and the main-actor ``InMemoryViewContext`` can operate
/// on the same instance concurrently. Under Embedded Swift the lock is elided:
/// with a concurrency runtime the backing is only ever touched from within its
/// owning actor, and without one (e.g. bare-metal ARM, where ``ModelStorage``
/// itself is unavailable) this synchronous store is the storage API, used
/// directly from the single-threaded main loop.
internal final class InMemoryStorage {

    /// The schema entities are validated against.
    public let model: Model

    /// The mutable state, only reachable through ``withState(_:)``.
    private struct State {

        var objects = [EntityName: [ObjectID: ModelData]]()

        var functions = [String: DatabaseFunction]()
    }

    #if hasFeature(Embedded)
    private var state = State()
    #else
    private let state = Locked(State())
    #endif

    public init(model: Model) {
        self.model = model
    }

    private func withState<T, E>(_ body: (inout State) throws(E) -> T) throws(E) -> T where E: Error {
        #if hasFeature(Embedded)
        return try body(&state)
        #else
        return try state.withValue { (state) throws(E) in
            try body(&state)
        }
        #endif
    }

    public func fetch(_ entity: EntityName, for id: ObjectID) throws(CoreModelError) -> ModelData? {
        try withState { (state) throws(CoreModelError) in
            try validate(entity)
            return state.objects[entity]?[id].map { normalized(entity: entity, $0, objects: state.objects) }
        }
    }

    public func fetch(_ fetchRequest: FetchRequest) throws(CoreModelError) -> [ModelData] {
        try withState { (state) throws(CoreModelError) in
            try validate(fetchRequest.entity)
            let values = (state.objects[fetchRequest.entity].map { Array($0.values) } ?? [])
                .map { normalized(entity: fetchRequest.entity, $0, objects: state.objects) }
            // objects of other entities are filtered out of the results, but let key paths
            // that traverse a relationship (e.g. `events.name`) resolve their related objects
            let related = state.objects
                .filter { $0.key != fetchRequest.entity }
                .flatMap { $0.value.values }
            return fetchRequest.evaluate(values + related, functions: state.functions)
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
    private func normalized(
        entity: EntityName,
        _ value: ModelData,
        objects: [EntityName: [ObjectID: ModelData]]
    ) -> ModelData {
        guard let description = model[entity] else { return value }
        var value = value
        for attribute in description.attributes {
            guard let existing = value.attributes[attribute.id] else {
                value.attributes[attribute.id] = .null
                continue
            }
            // A composite the caller only partly specified is filled out the same way,
            // one level down, so that a declared element decodes as the absence it
            // represents rather than as a missing key. An absent composite stays `.null`
            // rather than becoming a dictionary of nulls.
            guard case let .composite(elements) = attribute.type else { continue }
            value.attributes[attribute.id] = existing.normalized(for: elements)
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
        try withState { (state) throws(CoreModelError) in
            try validate(value.entity)
            // A key present in `value` overrides; a key the existing row already had that
            // `value` doesn't mention is preserved — the same "only touch the columns you
            // provided" semantics a SQL `ON CONFLICT DO UPDATE` or a Core Data managed object
            // gives for free. Without this, re-inserting a row from a batch that doesn't
            // touch every relationship (e.g. a site catalog refresh that never re-states
            // `parkingReservations`, which is written by an entirely separate sync) would
            // silently wipe those links instead of leaving them alone.
            //
            // This merge is per-property only: a composite attribute is replaced whole
            // rather than merged element-wise, matching Core Data's composite setter and
            // backends that store the composite as a single column or sub-document. Since
            // `normalized` makes every read well formed, a fetch/modify/insert round trip
            // still never loses elements.
            if var existing = state.objects[value.entity]?[value.id] {
                // - Note: Explicit loops rather than `Dictionary.merge(_:uniquingKeysWith:)` —
                //   the closure-based overload does dynamic casting internally, which is
                //   disallowed under Embedded Swift.
                for (key, attribute) in value.attributes {
                    existing.attributes[key] = attribute
                }
                for (key, relationship) in value.relationships {
                    existing.relationships[key] = relationship
                }
                state.objects[value.entity, default: [:]][value.id] = existing
            } else {
                state.objects[value.entity, default: [:]][value.id] = value
            }
        }
    }

    public func insert(_ values: [ModelData]) throws(CoreModelError) {
        for value in values {
            try insert(value)
        }
    }

    public func delete(_ entity: EntityName, for id: ObjectID) throws(CoreModelError) {
        try withState { (state) throws(CoreModelError) in
            try validate(entity)
            state.objects[entity]?[id] = nil
        }
    }

    public func delete(_ entity: EntityName, for ids: [ObjectID]) throws(CoreModelError) {
        try withState { (state) throws(CoreModelError) in
            try validate(entity)
            for id in ids {
                state.objects[entity]?[id] = nil
            }
        }
    }

    public func register(function: DatabaseFunction) {
        withState { state in
            state.functions[function.name] = function
        }
    }

    private func validate(_ entity: EntityName) throws(CoreModelError) {
        guard model[entity] != nil else {
            throw CoreModelError.invalidEntity(entity)
        }
    }
}

#if hasFeature(Embedded)
// - Note: Safe because the backing is confined to the owning actor, or to the
//   single-threaded main loop on targets without a concurrency runtime.
extension InMemoryStorage: @unchecked Sendable {}
#else
// - Note: Checked: `model` is an immutable `Sendable` value and every piece of
//   mutable state lives inside the ``Locked``.
extension InMemoryStorage: Sendable {}
#endif
