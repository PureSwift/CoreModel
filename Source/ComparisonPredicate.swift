//
//  ComparisonPredicate.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/25/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import SwiftFoundation

public struct ComparisonPredicate: JSONEncodable, JSONDecodable {
        
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

// MARK: - JSON

public extension ComparisonPredicate {
    
    init?(JSONValue: JSON.Value) {
        
        
    }
    
    func toJSON() -> JSON.Value {
        
        
    }
}
