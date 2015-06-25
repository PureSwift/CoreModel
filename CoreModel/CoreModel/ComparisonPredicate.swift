//
//  ComparisonPredicate.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/25/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public struct ComparisonPredicate<T>: Predicate {
    
    public let predicateType = PredicateType.Comparison
    
    public let predicateOperator: ComparisonPredicateOperator
    
    public let modifier: ComparisonPredicateModifier
    
    public let options: [ComparisonPredicateOption]?
    
    public let propertyName: String
    
    public let value: T
    
    public init(predicateOperator: ComparisonPredicateOperator, propertyName: String, value: T, modifier: ComparisonPredicateModifier = .All, options: [ComparisonPredicateOption]? = nil) {
        
        self.predicateOperator = predicateOperator
        self.modifier = modifier
        self.options = options
        self.propertyName = propertyName
        self.value = value
    }
}