//
//  NSManagedObject.swift
//  CoreDataModel
//
//  Created by Alsey Coleman Miller on 11/4/18.
//

#if canImport(CoreData)

import Foundation
import CoreData
import CoreModel
import Predicate

extension NSManagedObject: CoreModel.ManagedObject {
    
    public var store: NSManagedObjectContext? {
        
        return managedObjectContext
    }
    
    public func attribute(for key: String) -> AttributeValue {
        
        guard let objectValue = self.value(forKey: key)
            else { return .null }
        
        if let string = objectValue as? String {
            
            return .string(string)
            
        } else if let data = objectValue as? Data {
            
            return .data(data)
            
        } else if let date = objectValue as? Date {
            
            return .date(date)
            
        } else if let value = objectValue as? Bool {
            
            return .bool(value)
            
        } else if let value = objectValue as? Int16 {
            
            return .int16(value)
            
        } else if let value = objectValue as? Int32 {
            
            return .int32(value)
            
        } else if let value = objectValue as? Int64 {
            
            return .int64(value)
            
        } else if let value = objectValue as? Float {
            
            return .float(value)
            
        } else if let value = objectValue as? Double {
            
            return .double(value)
            
        } else {
            
            fatalError("Invalid CoreData attribute value \(objectValue)")
        }
    }
    
    public func setAttribute(_ newValue: AttributeValue, for key: String) {
        
        let objectValue: AnyObject?
        
        switch newValue {
        case .null:
            objectValue = nil
        case let .string(value):
            objectValue = value as NSString
        case let .data(value):
            objectValue = value as NSData
        case let .date(value):
            objectValue = value as NSDate
        case let .bool(value):
            objectValue = value as NSNumber
        case let .int16(value):
            objectValue = value as NSNumber
        case let .int32(value):
            objectValue = value as NSNumber
        case let .int64(value):
            objectValue = value as NSNumber
        case let .float(value):
            objectValue = value as NSNumber
        case let .double(value):
            objectValue = value as NSNumber
        }
        
        self.setValue(objectValue, forKey: key)
    }
    
    public func relationship(for key: String) -> RelationshipValue<NSManagedObject> {
        
        guard let objectValue = self.value(forKey: key)
            else { return .null }
        
        if let managedObject = objectValue as? NSManagedObject {
            
            return .toOne(managedObject)
            
        } else if let managedObjects = objectValue as? Set<NSManagedObject> {
            
            return .toMany(managedObjects)
        
        } else {
            
            fatalError("Invalid CoreData relationship value \(objectValue)")
        }
    }
    
    public func setRelationship(_ newValue: RelationshipValue<NSManagedObject>, for key: String) {
        
        let objectValue: AnyObject?
        
        switch newValue {
        case .null:
            objectValue = nil
        case let .toOne(managedObject):
            objectValue = managedObject
        case let .toMany(managedObjects):
            objectValue = managedObjects as NSSet
        }
        
        self.setValue(objectValue, forKey: key)
    }
}

#endif
