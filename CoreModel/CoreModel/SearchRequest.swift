//
//  SearchRequest.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public struct SearchRequest<T: ManagedObject> {
    
    let entity: Entity<T>
    
    let predicate: Predicate?
    
    let sortDescriptors: [SortDescriptor]
    
    let includesSubentities: Bool
    
    let fetchLimit: UInt?
    
    let fetchOffset: UInt?
    
    public init(entity: Entity<T>, predicate: Predicate? = nil, sortDescriptors: [SortDescriptor], includesSubentities: Bool = true, fetchLimit: UInt? = nil, fetchOffset: UInt? = nil) {
        
        self.entity = entity
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        self.includesSubentities = includesSubentities
        self.fetchLimit = fetchLimit
        self.fetchOffset = fetchOffset
    }
}