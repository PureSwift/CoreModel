//
//  Predicate.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/25/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import SwiftFoundation

public enum Predicate: JSONEncodable, JSONDecodable {
    
    case Comparison(ComparisonPredicate)
    case Compound(CompoundPredicate)
    
    public var type: PredicateType {
        
        switch self {
            
        case Comparison(_): return .Comparison
        case Compound(_):   return .Compound
        }
    }
}

public enum PredicateType: String {
    
    case Comparison
    case Compound
}

// MARK: - JSON

public extension Predicate {
    
    init?(JSONValue: JSON.Value) {
        
        guard let jsonObject = JSONValue.objectValue where jsonObject.count == 1,
            let (key, value) = jsonObject.first,
            let predicateType = PredicateType(rawValue: key)
            else { return nil }
        
        switch predicateType {
            
        case .Comparison:
            
            guard let comparisonPredicate = ComparisonPredicate(JSONValue: value) else { return nil }
            
            self = Predicate.Comparison(comparisonPredicate)
            
        case .Compound:
            
            guard let compoundPredicate = CompoundPredicate(JSONValue: value) else { return nil }
            
            self = Predicate.Compound(compoundPredicate)
        }
    }

    func toJSON() -> JSON.Value {
        
        let predicateJSON: JSON.Value
        
        switch self {
            
        case let .Comparison(predicate):    predicateJSON = predicate.toJSON()
        case let .Compound(predicate):      predicateJSON = predicate.toJSON()
        }
        
        return JSON.Value.Object([self.type.rawValue: predicateJSON])
    }
}