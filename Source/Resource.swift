//
//  Resource.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/23/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import SwiftFoundation

public struct Resource: JSONEncodable, JSONDecodable {
    
    public let entityName: String
    
    public let resourceID: String
    
    /// Initializes a resource with the specified resource ID.
    public init(_ entityName: String, resourceID: String) {
        
        self.entityName = entityName
        self.resourceID = resourceID
    }
    
    // MARK: - JSON
    
    public init?(JSONValue: JSON.Value) {
        
        switch JSONValue {
            
        case let .Object(jsonObject):
            
            guard let entityName = jsonObject.keys.first,
                let resourceID = jsonObject.values.first?.rawValue as? String
                where jsonObject.count == 1 else { return nil }
            
            self.entityName = entityName
            self.resourceID = resourceID
            
        default: return nil
        }
    }
    
    public func toJSON() -> JSON.Value {
        
        return JSON.Value.Object([entityName: .String(resourceID)])
    }
}

