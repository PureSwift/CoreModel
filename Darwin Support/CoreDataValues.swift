//
//  CoreDataValues.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/23/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import Foundation
import CoreData
import SwiftFoundation

public extension NSManagedObject {
    
    func values(store: CoreDataStore) throws -> ValuesObject {
        
        
    }
    
    /// Set the properties from a ```ValuesObject```. Does not save managed object context.
    func setValues(values: ValuesObject, store: CoreDataStore) throws {
        
        store.model.filter(<#T##includeElement: (Self.Generator.Element) -> Bool##(Self.Generator.Element) -> Bool#>)
        
        // sanity check
        guard store.validate(values, forEntity: <#T##Entity#>) else { throw StoreError.InvalidValues }
        
        for (key, value) in values {
            
            // validate entity exists
            guard let property = self.entity.propertiesByName[key] else { throw StoreError.InvalidValues }
            
            let value: AnyObject? = try {
                
                switch value {
                    
                case .Null: return nil
                    
                case .Attribute(let attributeValue):
                    
                    guard let attributeDescription = property as? NSAttributeDescription
                        else { throw StoreError.InvalidValues }
                    
                    let newValue = attributeValue.toCoreDataValue()
                    
                    guard attributeValue.isValidCoreDataValue(newValue, forAttribute: attributeDescription)
                        else { throw StoreError.InvalidValues }
                    
                    return newValue
                    
                case .Relationship(let relationshipValue):
                    
                    guard let relationshipDescription = property as? NSRelationshipDescription
                        else { throw StoreError.InvalidValues }
                    
                    switch relationshipValue {
                        
                    case .ToOne(let resourceID):
                        
                        guard let destinationObjectID = try store.findEntity(relationshipDescription.destinationEntity!, withResourceID: resourceID) else { throw StoreError.InvalidValues }
                        
                        let destinationManagedObject = store.managedObjectContext.objectWithID(destinationObjectID)
                        
                        return destinationManagedObject
                        
                    case .ToMany(let resourceIDs):
                        
                        var destinationManagedObjects = [NSManagedObject]()
                        
                        for resourceID in resourceIDs {
                            
                            guard let destinationObjectID = try store.findEntity(relationshipDescription.destinationEntity!, withResourceID: resourceID) else { throw StoreError.InvalidValues }
                            
                            let destinationManagedObject = store.managedObjectContext.objectWithID(destinationObjectID)
                            
                            destinationManagedObjects.append(destinationManagedObject)
                        }
                        
                        if relationshipDescription.ordered {
                            
                            return NSOrderedSet(array: destinationManagedObjects)
                        }
                        
                        return NSSet(array: destinationManagedObjects)
                    }
                }
                
                }()
            
            self.setValue(value, forKey: key)
        }
    }
}


public extension AttributeValue {
    
    init?(CoreDataValue: AnyObject) {
        
        
    }
    
    func toCoreDataValue() -> AnyObject {
        
        switch self {
            
        case .String(let value): return value
        case .Date(let value): return NSDate(date: value)
        case .Data(let value): return NSData(bytes: value)
        case .Number(let number):
            switch number {
                
            case .Boolean(let value): return NSNumber(bool: value)
            case .Integer(let value): return NSNumber(integer: value)
            case .Float(let value): return NSNumber(float: value)
            case .Double(let value): return NSNumber(double: value)
            case .Decimal(_): fatalError("Not Implemented") //return NSNumber(bool: value)
            }
        }
    }
}


