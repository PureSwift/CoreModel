//
//  SortDescriptor.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/25/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

public struct SortDescriptor: Codable, Equatable {
    
    public var ascending: Bool
    
    public var property: String
    
    public init(property: String, ascending: Bool = true) {
        
        self.property = property
        self.ascending = ascending
    }
}
