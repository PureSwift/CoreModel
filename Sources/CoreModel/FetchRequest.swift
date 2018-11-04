//
//  SearchRequest.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import Foundation
import Predicate

public struct FetchRequest: Equatable, Codable {
    
    public var entity: String
    
    public var sortDescriptors: [SortDescriptor]
    
    public var predicate: Predicate?
    
    public var fetchLimit: Int
    
    public var fetchOffset: Int
    
    public init(entity: String,
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
