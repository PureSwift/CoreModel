//
//  SearchRequest.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import SwiftFoundation

public struct FetchRequest: JSONEncodable, JSONParametrizedDecodable {
    
    public var entityName: String
    
    public var sortDescriptors: [SortDescriptor]
    
    public var predicate: Predicate?
    
    public var fetchLimit: Int = 0
    
    public var fetchOffset: Int = 0
    
    public init(entityName: String, sortDescriptors: [SortDescriptor] = []) {
        
        self.entityName = entityName
        self.sortDescriptors = sortDescriptors
    }
}

// MARK: - JSON

private extension FetchRequest {
    
    private enum JSONKey: String {
        
        case SortDescriptors
        case Predicate // Optional
        case FetchLimit // Optional
        case FetchOffset // Optional
    }
}

public extension FetchRequest {
    
    init?(JSONValue: JSON.Value, parameters: (entityName: String, entity: Entity)) {
        
        let entity = parameters.entity
        
        self.entityName = parameters.entityName
        
        guard let jsonObject = JSONValue.objectValue,
            let sortDescriptorsJSONArray = jsonObject[JSONKey.SortDescriptors.rawValue]?.arrayValue,
            let sortDescriptors = SortDescriptor.fromJSON(sortDescriptorsJSONArray)
            else { return nil }
        
        self.sortDescriptors = sortDescriptors
        
        if let fetchLimitJSON = jsonObject[JSONKey.FetchLimit.rawValue] {
            
            guard let fetchLimit = fetchLimitJSON.rawValue as? Int else { return nil }
            
            self.fetchLimit = fetchLimit
        }
        
        if let fetchOffsetJSON = jsonObject[JSONKey.FetchOffset.rawValue] {
            
            guard let fetchOffset = fetchOffsetJSON.rawValue as? Int else { return nil }
            
            self.fetchOffset = fetchOffset
        }
        
        if let predicateJSON = jsonObject[JSONKey.Predicate.rawValue] {
            
            guard let predicate = Predicate(JSONValue: predicateJSON, parameters: entity) else { return nil }
            
            self.predicate = predicate
        }
    }
    
    func toJSON() -> JSON.Value {
        
        var jsonObject = JSONObject()
        
        jsonObject[JSONKey.SortDescriptors.rawValue] = self.sortDescriptors.toJSON()
        
        jsonObject[JSONKey.Predicate.rawValue] = self.predicate?.toJSON()
        
        if self.fetchLimit > 0 {
            
            jsonObject[JSONKey.FetchLimit.rawValue] = JSON.Value.Number(.Integer(Int64(self.fetchLimit)))
        }
        
        if self.fetchOffset > 0 {
            
            jsonObject[JSONKey.FetchOffset.rawValue] = JSON.Value.Number(.Integer(Int64(self.fetchOffset)))
        }
        
        return JSON.Value.Object(jsonObject)
    }
}