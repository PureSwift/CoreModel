//
//  Resource.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/23/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public struct Resource<T: Entity> {
    
    let entity: T.Type
    
    let resourceID: String
    
    /// Initializes a resource with the specified resource ID.
    public init(entity: T.Type, resourceID: String) {
        
        self.entity = entity
        self.resourceID = resourceID
    }
}