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
        self.deleteRule = .nullifyDeleteRule
        switch relationship.type {
        case .toOne:
            self.minCount = 1
            self.maxCount = 1
            assert(!isToMany)
        case .toMany:
            self.minCount = 0
            self.maxCount = 0
            self.isOrdered = true
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
