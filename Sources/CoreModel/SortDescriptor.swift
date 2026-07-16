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
}
#endif
