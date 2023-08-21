//
//  NSEntityDescription.swift
//  
//
//  Created by Alsey Coleman Miller on 8/17/23.
//

#if canImport(CoreData)
import Foundation
import CoreData
import CoreModel

internal extension NSEntityDescription {
    
    convenience init(entity: EntityDescription) {
        self.init()
        self.name = entity.id.rawValue
        // add id attribute
        let id = NSAttributeDescription(
            attribute: Attribute(
                id: PropertyKey(rawValue: NSManagedObject.BuiltInProperty.id.rawValue),
                type: .string
            ),
            isOptional: false
        )
        // append properties
        var properties = [NSPropertyDescription]()
        properties.reserveCapacity(entity.attributes.count + entity.relationships.count + 1)
        properties.append(id)
        properties += entity.attributes.map { NSAttributeDescription(attribute: $0) }
        properties += entity.relationships.map { NSRelationshipDescription(relationship: $0) }
        self.properties = properties
        self.uniquenessConstraints = [[NSManagedObject.BuiltInProperty.id.rawValue as NSString]]
    }
}

#endif
