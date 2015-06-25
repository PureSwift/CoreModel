//
//  SortDescriptor.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/25/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public struct SortDescriptor {
    
    public let ascending: Bool
    
    public let propertyName: String
    
    public init(propertyName: String, ascending: Bool = true) {
        
        self.propertyName = propertyName
        self.ascending = ascending
    }
}