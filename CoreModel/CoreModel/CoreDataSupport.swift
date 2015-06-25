//
//  CoreDataSupport.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

public extension NSFetchRequest {
    
    func toSearchRequest<T: ManagedObject>() -> SearchRequest<T>? {
        
        return nil
    }
}

public extension CompoundPredicateType {
    
    public init(compoundPredicateTypeValue: NSCompoundPredicateType) {
        switch compoundPredicateTypeValue {
        case .NotPredicateType: self = .Not
        case .AndPredicateType: self = .And
        case .OrPredicateType: self = .Or
        }
    }
    
    public func toCompoundPredicateType() -> NSCompoundPredicateType {
        switch self {
        case .Not: return .NotPredicateType
        case .And: return .AndPredicateType
        case .Or: return .OrPredicateType
        }
    }
}

public extension ComparisonPredicateModifier {
        
    public init(comparisonPredicateModifierValue: NSComparisonPredicateModifier) {
        switch comparisonPredicateModifierValue {
        case .DirectPredicateModifier: self = .Direct
        case .AnyPredicateModifier: self = .Any
        case .AllPredicateModifier: self = .All
        }
    }
    
    public func toComparisonPredicateModifier() -> NSComparisonPredicateModifier {
        switch self {
        case .Direct: return .DirectPredicateModifier
        case .All: return .AllPredicateModifier
        case .Any: return .AnyPredicateModifier
        }
    }
}