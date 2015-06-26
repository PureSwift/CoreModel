//
//  Context.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public protocol Context {
    
    typealias ManagedObjectBaseType: ManagedObject
    
    var model: Model<ManagedObjectBaseType> { get }
    
    func delete<T: ManagedObject>(managedObject: T)
    
    func create<T: ManagedObject>(entity: Entity<T>) -> T
    
    func save() throws
    
    // MARK: - Fetching
    
    func performFetch<T: ManagedObject>(FetchRequest: FetchRequest<T>) throws -> T
    
    func findEntity<T: ManagedObject, I>(entity: Entity<T>, withUniqueIdentifier identifier: I, identifierAttribute Attribute<I>) -> T?
    
    func findOrCreateEntity<T: ManagedObject, I>(entity: Entity<T>, withUniqueIdentifier identifier: I, identifierAttribute Attribute<I>) -> T
}