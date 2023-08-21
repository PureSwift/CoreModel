//
//  SearchRequest.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import Foundation

/// CoreModel Fetch Request
public struct FetchRequest: Codable, Equatable, Hashable, Sendable {
    
    public var entity: EntityName
    
    public var sortDescriptors: [SortDescriptor]
    
    public var predicate: Predicate?
    
    public var fetchLimit: Int
    
    public var fetchOffset: Int
    
    public init(entity: EntityName,
                sortDescriptors: [SortDescriptor] = [],
                predicate: Predicate? = nil,
                fetchLimit: Int = 0,
                fetchOffset: Int = 0) {
        
        self.entity = entity
        self.sortDescriptors = sortDescriptors
        self.predicate = predicate
        self.fetchLimit = fetchLimit
        self.fetchOffset = fetchOffset
    }
}
