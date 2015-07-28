//
//  CoreDataFetchRequest.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/27/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import Foundation
import CoreData

public extension NSFetchRequest {
    
    convenience init(fetchRequest: FetchRequest, store: CoreDataStore) throws {
        
        self.init(entityName: fetchRequest.entityName)
        
        if let predicate = fetchRequest.predicate {
            
            self.predicate = try predicate.toPredicate(forFetchRequest: fetchRequest, store: store)
        }
        
        self.fetchLimit = Int(fetchRequest.fetchLimit)
        
        self.fetchOffset = Int(fetchRequest.fetchOffset)
        
        var sortDescriptors = [NSSortDescriptor]()
        
        for sortDescriptor in fetchRequest.sortDescriptors {
            
            sortDescriptors.append(NSSortDescriptor(key: sortDescriptor.propertyName, ascending: sortDescriptor.ascending))
        }
        
        self.sortDescriptors = sortDescriptors
    }
}

public extension Predicate {
    
    func toPredicate(forFetchRequest fetchRequest: FetchRequest, store: CoreDataStore) throws -> NSPredicate {
        
        switch self.predicateType {
            
        case .Comparison:
            
            let predicate = self as! ComparisonPredicate
            
            var rawOptionValue: UInt = 0
            
            if let options = predicate.options {
                
                for option in options {
                    
                    let convertedOption = option.toComparisonPredicateOption()
                    
                    rawOptionValue = rawOptionValue | convertedOption.rawValue
                }
            }
            
            let value: AnyObject? = {
               
                switch predicate.value {
                    
                case .Null: return nil
                    
                case .Attribute(let value): return value.toCoreDataValue()
                    
                case .Relationship(let value):
                    
                    guard let entity = store.managedObjectContext.persistentStoreCoordinator?.managedObjectModel.entitiesByName[fetchRequest.entityName]
                        else { fatalError() }
                    
                    let relationship = entity.relationshipsByName[key]
                    
                    switch value {
                        
                    case .ToOne(let resource):
                        
                        let objectID = store.findEntity(<#T##entity: NSEntityDescription##NSEntityDescription#>, withResourceID: <#T##String#>)
                    }
                }
                
            }()
            
            return NSComparisonPredicate(leftExpression: NSExpression(forKeyPath: predicate.propertyName),
                rightExpression: NSExpression(forConstantValue: value),
                modifier: predicate.modifier.toComparisonPredicateModifier(),
                type: predicate.predicateOperator.toPredicateOperatorType(),
                options: NSComparisonPredicateOptions(rawValue: rawOptionValue))
            
        case .Compound:
            
            
        }
    }
}

public extension ComparisonPredicateOperator {
    
    public init?(predicateOperatorTypeValue: NSPredicateOperatorType) {
        switch predicateOperatorTypeValue {
        case .LessThanPredicateOperatorType: self = .LessThan
        case .LessThanOrEqualToPredicateOperatorType: self = .LessThanOrEqualTo
        case .GreaterThanPredicateOperatorType: self = .GreaterThan
        case .GreaterThanOrEqualToPredicateOperatorType: self = .GreaterThanOrEqualTo
        case .EqualToPredicateOperatorType: self = .EqualTo
        case .NotEqualToPredicateOperatorType: self = .NotEqualTo
        case .MatchesPredicateOperatorType: self = .Matches
        case .LikePredicateOperatorType: self = .Like
        case .BeginsWithPredicateOperatorType: self = .BeginsWith
        case .EndsWithPredicateOperatorType: self = .EndsWith
        case .InPredicateOperatorType: self = .In
        case .ContainsPredicateOperatorType: self = .Contains
        case .BetweenPredicateOperatorType: self = .Between
        default: return nil
        }
    }
    
    public func toPredicateOperatorType() -> NSPredicateOperatorType {
        switch self {
        case .LessThan: return .LessThanPredicateOperatorType
        case .LessThanOrEqualTo: return .LessThanOrEqualToPredicateOperatorType
        case .GreaterThan: return .GreaterThanPredicateOperatorType
        case .GreaterThanOrEqualTo: return .GreaterThanOrEqualToPredicateOperatorType
        case .EqualTo: return .EqualToPredicateOperatorType
        case .NotEqualTo: return .NotEqualToPredicateOperatorType
        case .Matches: return .MatchesPredicateOperatorType
        case .Like: return .LikePredicateOperatorType
        case .BeginsWith: return .BeginsWithPredicateOperatorType
        case .EndsWith: return .EndsWithPredicateOperatorType
        case .In: return .InPredicateOperatorType
        case .Contains: return .ContainsPredicateOperatorType
        case .Between: return .BetweenPredicateOperatorType
        }
    }
}

public extension ComparisonPredicateOption {
    
    public func toComparisonPredicateOption() -> NSComparisonPredicateOptions {
        switch self {
        case .CaseInsensitive: return .CaseInsensitivePredicateOption
        case .DiacriticInsensitive: return .DiacriticInsensitivePredicateOption
        case .Normalized: return .NormalizedPredicateOption
        case .LocaleSensitive: return NSComparisonPredicateOptions(rawValue: 0x08)
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