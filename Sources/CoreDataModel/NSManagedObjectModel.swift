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
    
    convenience init(model: Model) {
        self.init()
        // create entities
        self.entities = model.entities.map { NSEntityDescription(entity: $0) }
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
