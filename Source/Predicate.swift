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
        
        guard let jsonObject = JSONValue.objectValue else {  }
    }
    
    func toJSON() -> JSON.Value {
        
        let predicateJSON =
    }
}