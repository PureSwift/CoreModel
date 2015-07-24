//
//  SortDescriptor.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/25/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

public struct SortDescriptor {
    
    public var ascending: Bool
    
    public var propertyName: String
    
    public init(propertyName: String, ascending: Bool = true) {
        
        self.propertyName = propertyName
        self.ascending = ascending
    }
}