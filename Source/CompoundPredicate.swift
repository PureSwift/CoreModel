//
//  CompoundPredicate.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/25/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import SwiftFoundation

public struct CompoundPredicate: JSONEncodable, JSONDecodable {
        
    public var type: CompoundPredicateType
    
    public var subpredicates: [Predicate]
    
    public init(type: CompoundPredicateType, subpredicates: [Predicate]) {
        
        self.type = type
        self.subpredicates = subpredicates
    }
}

// MARK: - JSON

private extension CompoundPredicate {
    
    private enum JSONKey: String {
        
        case CompoundPredicateType = "Type"
        case Subpredicates
    }
}

public extension CompoundPredicate {
    
    init?(JSONValue: JSON.Value) {
        
        guard let jsonObject = JSONValue.objectValue where jsonObject.count == 2,
            let typeString = jsonObject[JSONKey.CompoundPredicateType.rawValue]?.rawValue as? String,
            let type = CompoundPredicateType(rawValue: typeString),
            let subpredicatesJSONArray = jsonObject[JSONKey.Subpredicates.rawValue]?.rawValue as? JSONArray,
            let subpredicates = Predicate.fromJSON(subpredicatesJSONArray)
            else { return nil }
        
        self.type = type
        self.subpredicates = subpredicates
    }
    
    func toJSON() -> JSON.Value {
        
        var jsonObject = JSON.Object()
        
        jsonObject[JSONKey.CompoundPredicateType.rawValue] = JSON.Value.String(self.type.rawValue)
        
        jsonObject[JSONKey.Subpredicates.rawValue] = self.subpredicates.toJSON()
        
        return JSON.Value.Object(jsonObject)
    }
}