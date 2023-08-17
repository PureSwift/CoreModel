//
//  ManagedObject.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 11/4/18.
//

import Foundation

/// CoreModel Managed Object
public protocol ManagedObject: AnyObject, Hashable {
    
    /// Whether the object has been deleted.
    var isDeleted: Bool { get }
    
    func attribute(for key: PropertyKey) -> AttributeValue
    
    func setAttribute(_ newValue: AttributeValue, for key: PropertyKey)
    
    func relationship(for key: PropertyKey) -> RelationshipValue<Self>
    
    func setRelationship(_ newValue: RelationshipValue<Self>, for key: PropertyKey)
}
