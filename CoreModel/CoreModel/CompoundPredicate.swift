//
//  CompoundPredicate.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/25/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public struct CompoundPredicate: Predicate {
    
    public let predicateType = PredicateType.Compound
    
    public let compoundPredicateType: CompoundPredicateType
    
    public let subpredicates: [Predicate]
}