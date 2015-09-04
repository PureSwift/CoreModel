//
//  SearchRequest.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

public struct FetchRequest {
    
    public var entityName: String
    
    public var sortDescriptors: [SortDescriptor]
    
    public var predicate: Predicate?
    
    public var fetchLimit: Int = 0
    
    public var fetchOffset: Int = 0
    
    public init(entityName: String, sortDescriptors: [SortDescriptor]) {
        
        self.entityName = entityName
        self.sortDescriptors = sortDescriptors
    }
}