//
//  NSManagedObject.swift
//  CoreDataModel
//
//  Created by Alsey Coleman Miller on 11/4/18.
//

#if canImport(CoreData)
import Foundation
@_exported import CoreData
@_exported import CoreModel

internal extension NSManagedObject {
    
    enum BuiltInProperty: String {
        
        case id = "_id"
    }
}

internal extension AttributeValue {

    /// Decode a CoreData object value using the attribute type declared by the schema.
    ///
    /// The declared type is required, not merely convenient: an `NSNumber` alone can't
    /// distinguish a bool from an `int16` from a `double`.
    init(coreDataValue: Any, type: AttributeType, key: PropertyKey) throws {
        switch type {
        case .bool:
            guard let value = coreDataValue as? Bool else { throw Self.invalid(coreDataValue, key) }
            self = .bool(value)
        case .int16:
            guard let value = coreDataValue as? Int16 else { throw Self.invalid(coreDataValue, key) }
            self = .int16(value)
        case .int32:
            guard let value = coreDataValue as? Int32 else { throw Self.invalid(coreDataValue, key) }
            self = .int32(value)
        case .int64:
            guard let value = coreDataValue as? Int64 else { throw Self.invalid(coreDataValue, key) }
            self = .int64(value)
        case .float:
            guard let value = coreDataValue as? Float else { throw Self.invalid(coreDataValue, key) }
            self = .float(value)
        case .double:
            guard let value = coreDataValue as? Double else { throw Self.invalid(coreDataValue, key) }
            self = .double(value)
        case .string:
            guard let value = coreDataValue as? String else { throw Self.invalid(coreDataValue, key) }
            self = .string(value)
        case .data:
            guard let value = coreDataValue as? Data else { throw Self.invalid(coreDataValue, key) }
            self = .data(value)
        case .date:
            guard let value = coreDataValue as? Date else { throw Self.invalid(coreDataValue, key) }
            self = .date(value)
        case .uuid:
            guard let value = coreDataValue as? UUID else { throw Self.invalid(coreDataValue, key) }
            self = .uuid(value)
        case .url:
            guard let value = coreDataValue as? URL else { throw Self.invalid(coreDataValue, key) }
            self = .url(value)
        case .decimal:
            guard let value = coreDataValue as? NSDecimalNumber else { throw Self.invalid(coreDataValue, key) }
            self = .decimal(value as Decimal)
        case let .composite(elements):
            guard let dictionary = coreDataValue as? [String: Any] else {
                throw CoreDataModelError.invalidCompositeValue(key)
            }
            self = .composite(try AttributeValue.composite(from: dictionary, elements: elements))
        }
    }

    /// Convert the dictionary CoreData stores for a composite attribute.
    ///
    /// Iterates the declared elements rather than the stored dictionary, so that a stale
    /// or unknown key is ignored rather than mis-typed, and materializes an absent
    /// element as `.null` so that the shape always matches the schema.
    static func composite(
        from dictionary: [String: Any],
        elements: [Attribute]
    ) throws -> [PropertyKey: AttributeValue] {
        var values = [PropertyKey: AttributeValue](minimumCapacity: elements.count)
        for element in elements {
            // elements are always optional, so a missing key and NSNull both mean null
            guard let raw = dictionary[element.id.rawValue], raw is NSNull == false else {
                values[element.id] = .null
                continue
            }
            values[element.id] = try AttributeValue(coreDataValue: raw, type: element.type, key: element.id)
        }
        return values
    }

    private static func invalid(_ value: Any, _ key: PropertyKey) -> any Error {
        assertionFailure("Invalid CoreData attribute value \(value) for \(key)")
        return CocoaError(.coreData)
    }
}

internal extension NSManagedObject {

    func attribute(for key: PropertyKey) throws -> AttributeValue {
        
        guard let objectValue = self.value(forKey: key.rawValue)
            else { return .null }
        
        guard let coreDataAttribute = entity.attributesByName[key.rawValue] else {
            assertionFailure("Unknown CoreData attribute \(key)")
            throw CocoaError(.coreData)
        }
        
        guard let attributeType = AttributeType(attribute: coreDataAttribute) else {
            assertionFailure("Invalid CoreData attribute \(coreDataAttribute)")
            throw CocoaError(.coreData)
        }

        return try AttributeValue(coreDataValue: objectValue, type: attributeType, key: key)
    }

    func setAttribute(_ newValue: AttributeValue, for key: PropertyKey) {

        self.setValue(newValue.toFoundation(), forKey: key.rawValue)
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
        var cache = NSManagedObjectContext.ManagedObjectCache()
        try setRelationship(newValue, for: key, in: context, cache: &cache)
    }

    func setRelationship(
        _ newValue: RelationshipValue,
        for key: PropertyKey,
        in context: NSManagedObjectContext,
        cache: inout NSManagedObjectContext.ManagedObjectCache
    ) throws {

        guard let relationship = self.entity.relationshipsByName[key.rawValue],
              let destinationEntity = relationship.destinationEntity?.name.map({ EntityName(rawValue: $0) }) else {
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
            let managedObject = try context.find(destinationEntity, for: value, cache: &cache)
            objectValue = managedObject
        case let .toMany(value):
            guard relationship.isToMany else {
                assertionFailure("Invalid value \(newValue) for \"\(key)\"")
                throw CocoaError(.coreData)
            }
            // find or create
            let managedObjects = try value
                .map { try context.find(destinationEntity, for: $0, cache: &cache) ?? context.create(destinationEntity, for: $0, in: model, cache: &cache) }
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
                    let _ = AttributeType(attribute: attribute) else {
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

internal extension NSManagedObject {
    
    func setValues(for value: ModelData, in context: NSManagedObjectContext) throws {
        var cache = NSManagedObjectContext.ManagedObjectCache()
        try setValues(for: value, in: context, cache: &cache)
    }

    func setValues(
        for value: ModelData,
        in context: NSManagedObjectContext,
        cache: inout NSManagedObjectContext.ManagedObjectCache
    ) throws {
        // apply attributes
        for (key, value) in value.attributes {
            setAttribute(value, for: key)
        }
        // apply relationships
        for (key, value) in value.relationships {
            try setRelationship(value, for: key, in: context, cache: &cache)
        }
    }
}

internal extension ModelData {
    
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
