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

internal extension NSManagedObject {
    
    enum BuiltInProperty: String {
        
        case id = "_id"
    }
}

internal extension NSManagedObject {
    
    func attribute(for key: PropertyKey) throws -> AttributeValue {
        
        guard let objectValue = self.value(forKey: key.rawValue)
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
            assertionFailure("Invalid CoreData attribute value \(objectValue)")
            throw CocoaError(.coreData)
        }
    }
    
    func setAttribute(_ newValue: AttributeValue, for key: PropertyKey) {
        
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
        
        self.setValue(objectValue, forKey: key.rawValue)
    }
    
    func relationship(for key: PropertyKey) throws -> RelationshipValue {
        
        guard let objectValue = self.value(forKey: key.rawValue)
            else { return .null }
        
        guard let relationship = self.entity.relationshipsByName[key.rawValue] else {
            assertionFailure("Invalid relationship \"\(key)\"")
            throw CocoaError(.coreData)
        }
        
        if relationship.isToMany {
            if relationship.isOrdered {
                guard let orderedSet = objectValue as? NSOrderedSet else {
                    assertionFailure("Invalid type \(objectValue)")
                    throw CocoaError(.coreData)
                }
                let objectIDs = try orderedSet.map { try ($0 as! NSManagedObject).modelObjectID }
                return .toMany(objectIDs)
            } else {
                guard let managedObjects = objectValue as? Set<NSManagedObject> else {
                    assertionFailure("Invalid type \(objectValue)")
                    throw CocoaError(.coreData)
                }
                let objectIDs = try managedObjects.map { try $0.modelObjectID }
                return .toMany(objectIDs)
            }
        } else {
            guard let managedObject = self.value(forKey: key.rawValue) as? NSManagedObject else {
                assertionFailure("Invalid type \(objectValue)")
                throw CocoaError(.coreData)
            }
            return try .toOne(managedObject.modelObjectID)
        }
    }
    
    func setRelationship(
        _ newValue: RelationshipValue,
        for key: PropertyKey,
        in context: NSManagedObjectContext
    ) throws {
        
        guard let entityName = self.entity.name.map({ EntityName(rawValue: $0) }) else {
            assertionFailure("Missing entity name")
            throw CocoaError(.coreData)
        }
        
        guard let relationship = self.entity.relationshipsByName[key.rawValue] else {
            assertionFailure("Invalid relationship for \"\(key)\"")
            throw CocoaError(.coreData)
        }
        
        let model = self.entity.managedObjectModel
        
        let objectValue: AnyObject?
        
        switch newValue {
        case .null:
            objectValue = nil
        case let .toOne(value):
            guard relationship.isToMany == false else {
                assertionFailure("Invalid value \(newValue) for \"\(key)\"")
                throw CocoaError(.coreData)
            }
            // find managed object
            let managedObject = try context.find(entityName, for: value, in: model)
            objectValue = managedObject
        case let .toMany(value):
            guard relationship.isToMany else {
                assertionFailure("Invalid value \(newValue) for \"\(key)\"")
                throw CocoaError(.coreData)
            }
            // find or create
            let managedObjects = try value
                .map { try context.find(entityName, for: $0, in: model) ?? context.create(entityName, for: $0, in: model) }
            if relationship.isOrdered {
                objectValue = NSOrderedSet(array: managedObjects)
            } else {
                objectValue = NSSet(array: managedObjects)
            }
        }
        
        self.setValue(objectValue, forKey: key.rawValue)
    }
}

internal extension NSManagedObject {
    
    var modelObjectID: ObjectID {
        get throws {
            guard let string = self.value(forKey: BuiltInProperty.id.rawValue) as? String else {
                assertionFailure("Missing id value")
                throw CocoaError(.coreData)
            }
            return ObjectID(rawValue: string)
        }
    }
    
    var modelAttributes: [PropertyKey: AttributeValue] {
        get throws {
            let attributesByName = self.entity.attributesByName
            var attributes = [PropertyKey: AttributeValue]()
            attributes.reserveCapacity(attributesByName.count)
            for (key, attribute) in attributesByName {
                guard NSManagedObject.BuiltInProperty(rawValue: key) == nil,
                    let _ = AttributeType(attributeType: attribute.attributeType) else {
                    continue
                }
                let property = PropertyKey(rawValue: key)
                attributes[property] = try self.attribute(for: property)
            }
            return attributes
        }
    }
    
    var modelRelationships: [PropertyKey: RelationshipValue] {
        get throws {
            let relationshipsByName = self.entity.relationshipsByName
            var relationships = [PropertyKey: RelationshipValue]()
            relationships.reserveCapacity(relationshipsByName.count)
            for key in relationshipsByName.keys {
                let property = PropertyKey(rawValue: key)
                relationships[property] = try self.relationship(for: property)
            }
            return relationships
        }
    }
}

internal extension ModelInstance {
    
    init(managedObject: NSManagedObject) throws {
        guard let entityName = managedObject.entity.name.map({ EntityName(rawValue: $0) }) else {
            assertionFailure("Missing entity name")
            throw CocoaError(.coreData)
        }
        try self.init(
            entity: entityName,
            id: managedObject.modelObjectID,
            attributes: managedObject.modelAttributes,
            relationships: managedObject.modelRelationships
        )
    }
}

#endif
