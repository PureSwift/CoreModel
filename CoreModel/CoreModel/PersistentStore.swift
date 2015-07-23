//
//  PersistentStore.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/22/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public protocol PersistentStore {
    
    func newResourceID(forEntity entityName: String) -> String
    
    func create(entity entityName: String, initialValues: [String: AnyObject]) -> Entity
    
    func delete(entity entityName: String, resourceID: String)
}