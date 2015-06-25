//
//  Context.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public protocol Context {
    
    typealias ManagedObjectType = ManagedObject
    
    var model: Model<ManagedObjectType> { get }
    
    func performSearch<T: ManagedObject>(searchRequest: SearchRequest<T>) throws -> T
    
    func delete<T: ManagedObject>(managedObject: T) throws
    
    func create<T: ManagedObject, E: Entity<T>>(entity: E, withInitialValue values: [Property: Any]) -> T
}