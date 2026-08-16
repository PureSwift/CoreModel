//
//  NSManagedObjectModel.swift
//  
//
//  Created by Alsey Coleman Miller on 8/17/23.
//

#if canImport(CoreData)
import Foundation
import CoreData
import CoreModel

public extension NSManagedObjectModel {
    
    /// - Precondition: A model containing composite attributes may only back an
    /// `NSSQLiteStoreType` store. Adding an atomic store (in-memory, XML, or binary)
    /// for such a model raises an `NSInvalidArgumentException` — "Core Data provided
    /// atomic stores do not support composite attributes" — which is an Objective-C
    /// exception and therefore cannot be caught from Swift.
    ///
    /// - Throws: ``CoreDataModelError/compositeAttributesUnavailable(_:_:)`` when the
    /// model declares a composite attribute but the platform is older than
    /// macOS 14 / iOS 17 / tvOS 17 / watchOS 10, and
    /// ``CoreDataModelError/emptyCompositeAttribute(_:)`` for a composite with no elements.
    convenience init(model: Model) throws {
        self.init()
        // create entities
        var entities = [NSEntityDescription]()
        entities.reserveCapacity(model.entities.count)
        for entity in model.entities {
            entities.append(try NSEntityDescription(entity: entity))
        }
        self.entities = entities
        // set inverse relationships
        for entity in model.entities {
            guard let entityDescription = self.entitiesByName[entity.id.rawValue] else {
                assertionFailure()
                continue
            }
            for relationship in entity.relationships {
                guard let relationshipDescription = entityDescription.relationshipsByName[relationship.id.rawValue] else {
                    assertionFailure("Relationship not found")
                    continue
                }
                relationshipDescription.setInverseRelationship(relationship, model: self)
            }
        }
    }
}

internal extension NSManagedObjectModel {
    
    subscript(entityName: EntityName) -> NSEntityDescription {
        get throws {
            guard let entity = self.entitiesByName[entityName.rawValue]
                else { throw CoreModelError.invalidEntity(entityName) }
            return entity
        }
    }
}
#endif
