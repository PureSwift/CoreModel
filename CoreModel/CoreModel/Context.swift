//
//  Context.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public protocol Context {
    
    typealias EntityType: Entity
    
    typealias ModelType: Model where Model.EntityType == EntityType
    
    var model: Model { get }
}