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
    
    func attribute(for key: String) -> AttributeValue
    
    func setAttribute(_ newValue: AttributeValue, for key: String)
    
    func relationship(for key: String) -> RelationshipValue<Self>
    
    func setRelationship(_ newValue: RelationshipValue<Self>, for key: String)
}
