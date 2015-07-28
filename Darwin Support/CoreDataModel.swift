//
//  CoreDataModel.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/23/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import Foundation
import CoreData

public extension NSManagedObjectModel {
    
    func toModel(resourceIDAttributeName: String) -> [Entity]? {
        
        var model = [Entity]()
        
        for entityDescription in self.entities {
            
            guard let entity = entityDescription.toEntity(resourceIDAttributeName) else { return nil }
            
            model.append(entity)
        }
        
        return model
    }
}

public extension NSEntityDescription {
    
    func toEntity(resourceIDAttributeName: String) -> Entity? {
        
        var attributes = [Attribute]()
        
        for (key, description) in self.attributesByName {
            
            guard key != resourceIDAttributeName else { continue }
            
            guard let attribute = description.toAttribute() else { return nil }
            
            attributes.append(attribute)
        }
        
        var relationships = [Relationship]()
        
        for (_, description) in self.relationshipsByName {
            
            guard let relationship = description.toRelationship() else { return nil }
            
            relationships.append(relationship)
        }
        
        guard let entityName = self.name else { return nil }
        
        var entity = Entity(entityName: entityName)
        
        entity.attributes = attributes
        
        entity.relationships = relationships
        
        return entity
    }
}

public extension NSRelationshipDescription {
    
    func toRelationship() -> Relationship? {
        
        guard let destinationEntityName = self.destinationEntity?.name else { return nil }
        
        guard let inverseRelationshipName = self.inverseRelationship?.name else { return nil }
        
        return Relationship(name: self.name, propertyType: RelationshipType(toMany: self.toMany), destinationEntityName: destinationEntityName, inverseRelationshipName: inverseRelationshipName)
    }
}

public extension NSAttributeDescription {
    
    func toAttribute() -> Attribute? {
        
        guard let attributeType = self.attributeType.toAttributeType() else { return nil }
        
        return Attribute(name: name, propertyType: attributeType, optional: self.optional)
    }
}

public extension NSAttributeType {
    
    func toAttributeType() -> AttributeType? {
        
        switch self {
            
        case .Integer16AttributeType, .Integer32AttributeType, .Integer64AttributeType:
            return .Number(.Integer)
            
        case .DecimalAttributeType: return .Number(.Decimal)
            
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