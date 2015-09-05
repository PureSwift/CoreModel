//
//  SearchRequest.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import SwiftFoundation

public struct FetchRequest: JSONEncodable, JSONDecodable {
    
    public var entityName: String
    
    public var sortDescriptors: [SortDescriptor]
    
    public var predicate: Predicate?
    
    public var fetchLimit: Int = 0
    
    public var fetchOffset: Int = 0
    
    public init(entityName: String, sortDescriptors: [SortDescriptor]) {
        
        self.entityName = entityName
        self.sortDescriptors = sortDescriptors
    }
}

// MARK: - JSON

private extension FetchRequest {
    
    private enum JSONKey: String {
        
        case EntityName
        case SortDescriptors
        case Predicate // Optional
        case FetchLimit // Optional
        case FetchOffset // Optional
    }
}

public extension FetchRequest {
    
    init?(JSONValue: JSON.Value) {
        
        
    }
    
    func toJSON() -> JSON.Value {
        
        var jsonObject = JSONObject()
        
        jsonObject[JSONKey.EntityName.rawValue] = JSON.Value.String(self.entityName)
    }
}