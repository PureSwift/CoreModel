//
//  ComparisonPredicate.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/25/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

public struct ComparisonPredicate {
    
    public let predicateType = PredicateType.Comparison
    
    public var predicateOperator: ComparisonPredicateOperator
    
    public var modifier: ComparisonPredicateModifier
    
    public var options: [ComparisonPredicateOption]?
    
    public var propertyName: String
    
    public var value: Value
    
    public init(predicateOperator: ComparisonPredicateOperator = .EqualTo,
        propertyName: String,
        value: Value,
        modifier: ComparisonPredicateModifier = .All,
        options: [ComparisonPredicateOption]? = nil) {
        
        self.predicateOperator = predicateOperator
        self.modifier = modifier
        self.options = options
        self.propertyName = propertyName
        self.value = value
    }
}