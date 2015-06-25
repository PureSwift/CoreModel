//
//  SortDescriptor.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/25/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public struct SortDescriptor {
    
    public let ascending: Bool
    
    public let property: Property
    
    public init(property: Property, ascending: Bool = true) {
        
        self.property = property
        self.ascending = ascending
    }
}