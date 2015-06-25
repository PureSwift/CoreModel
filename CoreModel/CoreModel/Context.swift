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
    
    func performSearch<T: ManagedObject>(searchRequest: SearchRequest<T>) throws -> T
    
    func delete<T: ManagedObject>(managedObject: T)
    
    func create<T: ManagedObject>(entity: Entity<T>) -> T
    
    func save() throws
}