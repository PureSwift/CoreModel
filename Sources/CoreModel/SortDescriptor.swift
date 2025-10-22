//
//  SortDescriptor.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/25/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import Foundation

public extension FetchRequest {
    
    struct SortDescriptor: Codable, Equatable, Hashable, Sendable {
        
        public var property: PropertyKey
        
        public var ascending: Bool
        
        public init(property: PropertyKey, ascending: Bool = true) {
            self.property = property
            self.ascending = ascending
        }
    }
}

// MARK: - Foundation

#if canImport(Darwin)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public extension FetchRequest.SortDescriptor {
    
    /// Creates a ``FetchRequest.SortDescriptor`` from a ``Foundation.SortDescriptor``
    init<Root: NSObject>(_ sortDescriptor: Foundation.SortDescriptor<Root>) {
        let sortDescriptor = NSSortDescriptor(sortDescriptor)
        self.property = PropertyKey(rawValue: sortDescriptor.key ?? "")
        self.ascending = sortDescriptor.ascending
    }
}
#endif
