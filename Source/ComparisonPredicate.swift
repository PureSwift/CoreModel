//
//  ComparisonPredicate.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/25/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import SwiftFoundation

public struct ComparisonPredicate: JSONEncodable, JSONParametrizedDecodable {
    
    public var propertyName: String
    
    public var value: Value
    
    public var predicateOperator: ComparisonPredicateOperator
    
    public var modifier: ComparisonPredicateModifier
    
    public var options: [ComparisonPredicateOption]?
    
    public init(predicateOperator: ComparisonPredicateOperator = .EqualTo,
        propertyName: String,
        value: Value,
        modifier: ComparisonPredicateModifier = .Direct,
        options: [ComparisonPredicateOption]? = nil) {
        
        self.predicateOperator = predicateOperator
        self.modifier = modifier
        self.options = options
        self.propertyName = propertyName
        self.value = value
    }
}

// MARK: - JSON

private extension ComparisonPredicate {
    
    private enum JSONKey: String {
        
        case Property
        case Value
        case Operator
        case Modifier // Optional
        case Options // Optional
    }
}

public extension ComparisonPredicate {
    
    init?(JSONValue: JSON.Value, parameters: Entity) {
        
        let entity = parameters
        
        // required values
        guard let jsonObject = JSONValue.objectValue,
            let propertyName = jsonObject[JSONKey.Property.rawValue]?.rawValue as? String,
            let valueJSON = jsonObject[JSONKey.Value.rawValue],
            let operatorString = jsonObject[JSONKey.Operator.rawValue]?.rawValue as? String,
            let predicateOperator = ComparisonPredicateOperator(rawValue: operatorString),
            let modifierString = jsonObject[JSONKey.Modifier.rawValue]?.rawValue as? String,
            let modifier = ComparisonPredicateModifier(rawValue: modifierString)
            else { return nil }
        
        self.propertyName = propertyName
        self.predicateOperator = predicateOperator
        self.modifier = modifier
        
        // convert value
        guard let values = entity.convert([propertyName: valueJSON]) else { return nil }
        
        guard let value = values[propertyName] else { fatalError() }
        
        self.value = value
        
        // add options
        if let optionsJSON = jsonObject[JSONKey.Options.rawValue] {
            
            guard let optionsRawValues = optionsJSON.rawValue as? [String],
                let options = ComparisonPredicateOption.fromRawValues(optionsRawValues)
                else { return nil }
            
            self.options = options
        }
    }
    
    func toJSON() -> JSON.Value {
        
        var jsonObject = JSON.Object()
        
        
        
        return JSON.Value.Object(jsonObject)
    }
}

