//
//  SortDescriptor.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/25/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

public extension FetchRequest {

    struct SortDescriptor: Equatable, Hashable, Sendable {

        public var term: SortTerm

        public var ascending: Bool

        public init(term: SortTerm, ascending: Bool = true) {
            self.term = term
            self.ascending = ascending
        }

        public init(property: PropertyKey, ascending: Bool = true) {
            self.init(term: .property(property), ascending: ascending)
        }
    }

    /// What a ``FetchRequest.SortDescriptor`` sorts by — either a plain property,
    /// or the result of a function call expression (e.g. a custom function registered
    /// with the underlying store via ``DatabaseFunction``).
    enum SortTerm: Equatable, Hashable, Sendable {

        case property(PropertyKey)
        case function(Predicate.FunctionExpression)
    }
}

public extension FetchRequest.SortDescriptor {

    /// The property being sorted by, if this descriptor's term is `.property`.
    var property: PropertyKey? {
        guard case let .property(property) = term else { return nil }
        return property
    }
}

#if !hasFeature(Embedded)
extension FetchRequest.SortDescriptor: Codable {}
extension FetchRequest.SortTerm: Codable {}
#endif

// MARK: - Foundation

#if canImport(Darwin)
import Foundation

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public extension FetchRequest.SortDescriptor {

    /// Creates a ``FetchRequest.SortDescriptor`` from a ``Foundation.SortDescriptor``
    init<Root: NSObject>(_ sortDescriptor: Foundation.SortDescriptor<Root>) {
        let sortDescriptor = NSSortDescriptor(sortDescriptor)
        self.term = .property(PropertyKey(rawValue: sortDescriptor.key ?? ""))
        self.ascending = sortDescriptor.ascending
    }

    /// Converts to a ``Foundation.SortDescriptor`` comparing the specified root type.
    ///
    /// Returns `nil` for function-based sort terms, which have no Foundation equivalent.
    func toFoundation<Root: NSObject>(comparing root: Root.Type) -> Foundation.SortDescriptor<Root>? {
        guard let sortDescriptor = toFoundation() else {
            return nil
        }
        return Foundation.SortDescriptor(sortDescriptor, comparing: root)
    }
}

public extension FetchRequest.SortDescriptor {

    /// Creates a ``FetchRequest.SortDescriptor`` from an `NSSortDescriptor`.
    ///
    /// Returns `nil` if the sort descriptor has no key path.
    init?(_ sortDescriptor: NSSortDescriptor) {
        guard let key = sortDescriptor.key else {
            return nil
        }
        self.init(property: PropertyKey(rawValue: key), ascending: sortDescriptor.ascending)
    }

    /// Converts to an `NSSortDescriptor`.
    ///
    /// Returns `nil` for function-based sort terms, which have no Foundation equivalent.
    func toFoundation() -> NSSortDescriptor? {
        guard let property else {
            return nil
        }
        return NSSortDescriptor(key: property.rawValue, ascending: ascending)
    }
}
#endif
