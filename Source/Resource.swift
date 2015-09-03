//
//  Resource.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/23/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import SwiftFoundation

public struct Resource {
    
    public let entityName: String
    
    public let resourceID: String
    
    /// Initializes a resource with the specified resource ID.
    public init(entity: String, resourceID: String) {
        
        self.entityName = entity
        self.resourceID = resourceID
    }
}