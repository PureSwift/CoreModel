//
//  SearchRequest.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public struct FetchRequest<T: Entity> {
    
    public let entity: T.Type
    
    public var predicate: Predicate?
    
    public var sortDescriptors: [SortDescriptor]
    
    public var includesSubentities: Bool = true
    
    public var fetchLimit: UInt = 0
    
    public var fetchOffset: UInt = 0
    
    init(entity: T.Type, sortDescriptors: [SortDescriptor]) {
        
        self.entity = entity
        self.sortDescriptors = sortDescriptors
    }
}