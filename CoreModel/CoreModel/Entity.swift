//
//  Entity.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public struct Entity<T: ManagedObject> {
    
    public let name: String
    
    public let abstract: Bool
    
    public let properties: [Property]
    
    public let subentities: [Entity<T>]
}