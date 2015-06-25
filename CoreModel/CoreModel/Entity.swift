//
//  Entity.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//


public protocol Entity {
    
    typealias PropertyType = Property
    
    typealias EntityManagedObjectType = ManagedObject
    
    var name: String { get }
    
    var properties: [PropertyType] { get }
    
    var abstract: Bool { get }
    
    // var subentities: [Entity] { get }
}