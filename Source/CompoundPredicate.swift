//
//  CompoundPredicate.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/25/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import SwiftFoundation

public struct CompoundPredicate: JSONEncodable, JSONDecodable {
    
    public let predicateType = PredicateType.Compound
    
    public var compoundPredicateType: CompoundPredicateType
    
    public var subpredicates: [Predicate]
    
    public init(compoundPredicateType: CompoundPredicateType, subpredicates: [Predicate]) {
        
        self.compoundPredicateType = compoundPredicateType
        self.subpredicates = subpredicates
    }
}

// MARK: - JSON

public extension CompoundPredicate {
    
    init?(JSONValue: JSON.Value) {
        
        
    }
    
    func toJSON() -> JSON.Value {
        
        
    }
}