//
//  Store.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/22/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

/// CoreModel Store Protocol
public protocol StoreProtocol: AnyObject {
    
    associatedtype ManagedObject: CoreModel.ManagedObject
    
    /// Fetch managed objects.
    func fetch(_ fetchRequest: FetchRequest) throws -> [ManagedObject]
    
    /// Fetch and return result count.
    func count(_ fetchRequest: FetchRequest) throws -> Int
    
    /// Create new managed object.
    func create(_ entity: String) throws -> ManagedObject
    
    /// Delete the specified managed object. 
    func delete(_ managedObject: ManagedObject)
    
    /// Flush the store's pending changes to the underlying storage format.
    func save() throws
}

public extension StoreProtocol {
    
    func count(_ fetchRequest: FetchRequest) throws -> Int {
        
        return try fetch(fetchRequest).count
    }
}

/// CoreModel Store Error
public enum StoreError: Error {
    
    /// Invalid or unknown entity
    case invalidEntity(String)
}
