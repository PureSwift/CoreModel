//
//  SearchRequest.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public struct SearchRequest<T: ManagedObject> {
    
    let entity: Entity<T>
    
    let predicate: Predicate
    
    let sortDescriptors: [SortDescriptor]
    
    let includesSubentities: Bool
    
    let fetchLimit: Int
    
    let fetchOffset: Int
}