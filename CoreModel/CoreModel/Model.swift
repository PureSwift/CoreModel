//
//  Model.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

/** Describes the model information. */
public struct Model<M: ManagedObject> {
    
    public let entities: [Entity<M>]
    
    /** Creates a new model with the specified entities. Generic passed should be the **base** ```ManagedObject``` class and not a specific subclass. */
    public init(entities: [Entity<M>]) {
        
        self.entities = entities
    }
}