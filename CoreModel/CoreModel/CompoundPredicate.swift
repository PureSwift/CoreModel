//
//  CompoundPredicate.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/25/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

struct CompoundPredicate: Predicate {
    
    let predicateType = PredicateType.Compound
    
    let compoundPredicateType: CompoundPredicateType
    
    let subpredicates: [Predicate]
}