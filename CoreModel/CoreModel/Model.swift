//
//  Model.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public protocol Model {
    
    typealias EntityType: Entity
    
    var entities: [EntityType] { get }
}