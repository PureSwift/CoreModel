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

public final class CoreDataManagedObject: CoreModel.ManagedObject {
    
    internal let managedObject: NSManagedObject
    
    internal init(_ managedObject: NSManagedObject) {
        self.managedObject = managedObject
    }
    
    public var store: NSManagedObjectContext? {
        return managedObject.managedObjectContext
    }
    
    public var isDeleted: Bool {
        return managedObject.isDeleted
    }
    
    public func attribute(for key: String) -> AttributeValue {
        return managedObject.attribute(for: key)
    }
    
    public func setAttribute(_ newValue: AttributeValue, for key: String) {
        managedObject.setAttribute(newValue, for: key)
    }
    
    public func relationship(for key: String) -> RelationshipValue<CoreDataManagedObject> {
        
        guard let objectValue = managedObject.value(forKey: key)
            else { return .null }
        
        if let managedObject = objectValue as? NSManagedObject {
            return .toOne(CoreDataManagedObject(managedObject))
        } else if let orderedSet = objectValue as? NSOrderedSet {
            return .toMany(orderedSet.map { CoreDataManagedObject($0 as! NSManagedObject) })
        } else if let managedObjects = objectValue as? Set<NSManagedObject> {
            return .toMany(managedObjects.map { CoreDataManagedObject($0) })
        } else {
            fatalError("Invalid CoreData relationship value \(objectValue)")
        }
    }
    
    public func setRelationship(_ newValue: RelationshipValue<CoreDataManagedObject>, for key: String) {
        
        let objectValue: AnyObject?
        
        switch newValue {
        case .null:
            objectValue = nil
        case let .toOne(value):
            objectValue = value.managedObject
        case let .toMany(value):
            objectValue = Set(value.map({ $0.managedObject })) as NSSet
        }
        
        managedObject.setValue(objectValue, forKey: key)
    }
}

public extension CoreDataManagedObject {
    
    static func == (lhs: CoreDataManagedObject, rhs: CoreDataManagedObject) -> Bool {
        return lhs.managedObject == rhs.managedObject
    }
}

public extension CoreDataManagedObject {
    
    func hash(into hasher: inout Hasher) {
        managedObject.hash(into: &hasher)
    }
}

internal extension NSManagedObject {
    
    func attribute(for key: String) -> AttributeValue {
        
        guard let objectValue = self.value(forKey: key)
            else { return .null }
        
        if let string = objectValue as? String {
            return .string(string)
        } else if let uuid = objectValue as? UUID {
            return .uuid(uuid)
        } else if let url = objectValue as? URL {
            return .url(url)
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
    
    func setAttribute(_ newValue: AttributeValue, for key: String) {
        
        let objectValue: AnyObject?
        
        switch newValue {
        case .null:
            objectValue = nil
        case let .string(value):
            objectValue = value as NSString
        case let .uuid(value):
            objectValue = value as NSUUID
        case let .url(value):
            objectValue = value as NSURL
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
}

#endif
