//
//  Relationship.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public protocol Relationship: Property {
    
    typealias DestinationManagedObjectType = ManagedObject
    
    var destinationEntity: Entity<DestinationManagedObjectType> { get }
    
    var toMany: Bool { get }
}