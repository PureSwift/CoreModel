//
//  NSRelationshipDescription.swift
//  
//
//  Created by Alsey Coleman Miller on 8/17/23.
//

#if canImport(CoreData)
import Foundation
import CoreData
import CoreModel

internal extension NSRelationshipDescription {
    
    convenience init(relationship: Relationship) {
        self.init()
        self.name = relationship.id.rawValue
        self.deleteRule = .nullifyDeleteRule
        switch relationship.type {
        case .toOne:
            self.minCount = 1
            self.maxCount = 1
            assert(!isToMany)
        case .toMany:
            self.minCount = 0
            self.maxCount = 0
            // - Note: To-many relationships are deliberately *unordered*.
            //   CoreData forbids an ordered relationship whose inverse is also
            //   ordered — `momc` rejects it at build time, but a model built
            //   programmatically is never validated, so a many-to-many (e.g.
            //   `Person.events` / `Event.people`) silently produced an invalid
            //   model. Deleting an object then corrupted memory while CoreData
            //   propagated the delete through the faulted ordered set, crashing
            //   with EXC_BAD_ACCESS inside `-[NSManagedObject _propagateDelete:]`.
            //   ``RelationshipValue/toMany(_:)`` carries no ordering guarantee
            //   anyway, and unordered is CoreData's own default.
            assert(isToMany)
        }
    }
    
    func setInverseRelationship(_ relationship: Relationship, model: NSManagedObjectModel) {
        guard let destinationEntity = model.entitiesByName[relationship.destinationEntity.rawValue],
              let inverseRelationship = destinationEntity.relationshipsByName[relationship.inverseRelationship.rawValue] else {
            assertionFailure()
            return
        }
        self.inverseRelationship = inverseRelationship
        self.destinationEntity = destinationEntity
    }
}

#endif
