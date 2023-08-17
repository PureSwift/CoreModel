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
