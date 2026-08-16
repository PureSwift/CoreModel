//
//  FetchRequestEvaluation.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/21/26.
//  Copyright © 2026 PureSwift. All rights reserved.
//

public extension FetchRequest {

    /// Execute this fetch request against an in-memory collection of objects.
    ///
    /// Filters by entity and predicate, sorts by the sort descriptors
    /// (with a stable identifier tiebreaker), then applies the fetch offset and limit.
    ///
    /// Objects of other entities may be included; they're filtered out of the results but
    /// remain available for key paths that traverse a relationship (e.g. `events.name`).
    ///
    /// - Parameters:
    ///   - objects: The objects to evaluate the fetch request against.
    ///   - functions: Custom functions (keyed by name) that `.function` expressions can invoke.
    /// - Returns: The objects matching this fetch request, in sorted order.
    func evaluate(
        _ objects: [ModelData],
        functions: [String: DatabaseFunction] = [:]
    ) -> [ModelData] {
        var results = objects.filter { $0.entity == entity }
        if let predicate {
            let index = objects.index()
            results = results.filter { predicate.evaluate(with: $0, functions: functions, objects: index) }
        }
        results = results.sorted(by: sortDescriptors, functions: functions)
        if fetchOffset > 0 {
            results = Array(results.dropFirst(fetchOffset))
        }
        if fetchLimit > 0 {
            results = Array(results.prefix(fetchLimit))
        }
        return results
    }
}

public extension Array where Element == ModelData {

    /// Filter in memory by the given predicate.
    ///
    /// - Parameters:
    ///   - predicate: The predicate each object must satisfy.
    ///   - functions: Custom functions (keyed by name) that `.function` expressions can invoke.
    func filtered(
        by predicate: FetchRequest.Predicate,
        functions: [String: DatabaseFunction] = [:]
    ) -> [ModelData] {
        let index = self.index()
        return filter { predicate.evaluate(with: $0, functions: functions, objects: index) }
    }

    /// Index these objects by identifier, for resolving key paths that traverse a relationship.
    ///
    /// - Note: Built by hand rather than with `Dictionary.init(_:uniquingKeysWith:)`,
    ///   which relies on dynamic casting and is unavailable under Embedded Swift.
    internal func index() -> [ObjectID: ModelData] {
        var index = [ObjectID: ModelData](minimumCapacity: count)
        for object in self where index[object.id] == nil {
            index[object.id] = object
        }
        return index
    }

    /// Sort in memory by the given descriptors, resolving function terms with the
    /// registered functions. Property terms fall back to attribute ordering.
    ///
    /// Ties (and an empty descriptor list) are broken by ordering on the
    /// object identifier, so results are deterministic.
    func sorted(
        by sortDescriptors: [FetchRequest.SortDescriptor],
        functions: [String: DatabaseFunction] = [:]
    ) -> [ModelData] {
        sorted { first, second in
            for descriptor in sortDescriptors {
                let lhs: AttributeValue?
                let rhs: AttributeValue?
                switch descriptor.term {
                case let .property(property):
                    lhs = first.attributeValue(for: property)
                    rhs = second.attributeValue(for: property)
                case let .function(function):
                    let expression = FetchRequest.Predicate.Expression.function(function)
                    lhs = expression.evaluate(with: first, functions: functions)?.attributeValue
                    rhs = expression.evaluate(with: second, functions: functions)?.attributeValue
                }
                guard let comparison = AttributeValue.order(lhs, rhs), comparison != 0 else {
                    continue
                }
                return descriptor.ascending ? comparison < 0 : comparison > 0
            }
            // stable tiebreaker on the object identifier
            return first.id.rawValue < second.id.rawValue
        }
    }
}
