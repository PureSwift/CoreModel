//
//  SortDescriptor.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/25/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

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
