//
//  CoreDataModel.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/23/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

#if os(OSX)

import Foundation
import CoreData

public extension NSManagedObjectModel {
    
    /// Converts a **CoreData** model to **CoreModel** model.
    /// 
    /// -Note: The managed object model should not include the attribute that will be used for storing the
    /// resource ID. That attribute should be added later (programatically) for the **CoreData** stack.
    func toModel() -> Model? {
        
        var model = Model()
        
        for (name, entityDescription) in self.entitiesByName {
            
            guard let entity = entityDescription.toEntity() else { return nil }
            
            model[name] = entity
        }
        
        return model
    }
    
    /// Programatically adds a unique resource identifier attribute to each entity in the managed object model.
    func addResourceIDAttribute(resourceIDAttributeName: String) {
        
        // add a resourceID attribute to managed object model
        for (_, entity) in self.entitiesByName {
            
            if entity.superentity == nil {
                
                // create new (runtime) attribute
                let resourceIDAttribute = NSAttributeDescription()
                resourceIDAttribute.attributeType = NSAttributeType.StringAttributeType
                resourceIDAttribute.name = resourceIDAttributeName
                resourceIDAttribute.optional = false
                
                // add to entity
                entity.properties.append(resourceIDAttribute)
            }
        }
    }
    
    /// Programatically adds a date attribute to each entity in the managed object model.
    func addDateCachedAttribute(dateCachedAttributeName: String) {
        
        // add a date attribute to managed object model
        for (_, entity) in self.entitiesByName as [String: NSEntityDescription] {
            
            if entity.superentity == nil {
                
                // create new (runtime) attribute
                let dateAttribute = NSAttributeDescription()
                dateAttribute.attributeType = NSAttributeType.DateAttributeType
                dateAttribute.name = dateCachedAttributeName
                
                // add to entity
                entity.properties.append(dateAttribute)
            }
        }
    }
    
    /// Marks all properties as optional.
    func markAllPropertiesAsOptional() {
        
        // add a date attribute to managed object model
        for (_, entity) in self.entitiesByName as [String: NSEntityDescription] {
            
            for (_, property) in entity.propertiesByName as [String: NSPropertyDescription] {
                
                property.optional = true
            }
        }
    }
}

public extension NSEntityDescription {
    
    func toEntity() -> Entity? {
        
        var attributes = [String: Attribute]()
        
        for (name, description) in self.attributesByName {
            
            guard let attribute = description.toAttribute() else { return nil }
            
            attributes[name] = attribute
        }
        
        var relationships = [String: Relationship]()
        
        for (name, description) in self.relationshipsByName {
            
            guard let relationship = description.toRelationship() else { return nil }
            
            relationships[name] = relationship
        }
        
        var entity = Entity()
        
        entity.attributes = attributes
        
        entity.relationships = relationships
        
        return entity
    }
}

public extension NSRelationshipDescription {
    
    func toRelationship() -> Relationship? {
        
        guard let destinationEntityName = self.destinationEntity?.name else { return nil }
        
        guard let inverseRelationshipName = self.inverseRelationship?.name else { return nil }
        
        return Relationship(type: RelationshipType(toMany: self.toMany), destinationEntityName: destinationEntityName, inverseRelationshipName: inverseRelationshipName)
    }
}

public extension NSAttributeDescription {
    
    func toAttribute() -> Attribute? {
        
        guard let attributeType = self.attributeType.toAttributeType() else { return nil }
        
        return Attribute(type: attributeType)
    }
}

public extension NSAttributeType {
    
    func toAttributeType() -> AttributeType? {
        
        switch self {
            
        case .Integer16AttributeType, .Integer32AttributeType, .Integer64AttributeType:
            return .Number(.Integer)
            
        case .DecimalAttributeType: return .Number(.Double)
            
        case .DoubleAttributeType: return .Number(.Double)
            
        case .FloatAttributeType: return .Number(.Float)
            
        case .BooleanAttributeType: return .Number(.Boolean)
            
        case .StringAttributeType: return .String
            
        case .DateAttributeType: return .Date
            
        case .BinaryDataAttributeType: return .Data
            
        default: return nil
        }
    }
}

#endif
