//
//  MemoryStore.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/28/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import Foundation
import CoreData

/*
/// Implementation of In-Memory ```Store```.
public final class MemoryStore: Store {
    
    public let model: [Entity]
    
    /// Internal storage mapped to [EntityName: [ResourceID: Values]]
    private var storage = [String: [String: ValuesObject]]()
    
    public init(model: [Entity]) {
        
        self.model = model
        
        for entity in model {
            
            self.storage[entity.name] = [String: ValuesObject]()
        }
    }
    
    public func fetch(fetchRequest: FetchRequest) throws -> [Resource] {
        
        guard let resources = storage[fetchRequest.entityName] else {
            
            
        }
        
        if let predicate = fetchRequest.predicate else {
            
            
        }
        
        var results = [Resource]()
        
        for resourceID in resources.keys {
            
            if let predicate = fetchRequest.predicate else {
                
                
            }
        }
    }
    
    public func exists(resource: Resource) throws -> Bool {
        
        
    }
    
    public func exist(resources: [Resource]) throws -> Bool
    
    public func create(resource: Resource, initialValues: ValuesObject?) throws
    
    public func delete(resource: Resource) throws
    
    public func edit(resource: Resource, changes: ValuesObject) throws
    
    public func values(forResource resource: Resource) throws -> ValuesObject
}
*/

