//
//  CompoundPredicate.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/25/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public struct CompoundPredicate: Predicate {
    
    public let predicateType = PredicateType.Compound
    
    public var compoundPredicateType: CompoundPredicateType
    
    public var subpredicates: [Predicate]
    
    public init(compoundPredicateType: CompoundPredicateType, subpredicates: [Predicate]) {
        
        self.compoundPredicateType = compoundPredicateType
        self.subpredicates = subpredicates
    }
}