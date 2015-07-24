//
//  SearchRequest.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public struct FetchRequest {
    
    public var entityName: String
    
    public var sortDescriptors: [SortDescriptor]
    
    public var predicate: Predicate?
    
    public var fetchLimit: UInt = 0
    
    public var fetchOffset: UInt = 0
    
    public init(entityName: String, sortDescriptors: [SortDescriptor]) {
        
        self.entityName = entityName
        self.sortDescriptors = sortDescriptors
    }
}