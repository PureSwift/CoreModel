//
//  ComparisonPredicate.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/25/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

struct ComparisonPredicate: Predicate {
    
    let predicateType = PredicateType.Comparison
    
    let predicateOperator: ComparisonPredicateOperator
    
    let modifier: ComparisonPredicateModifier
    
    let options: [ComparisonPredicateOption]
}