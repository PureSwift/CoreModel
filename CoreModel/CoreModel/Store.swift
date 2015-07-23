//
//  Store.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/22/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public protocol Store {
    
    // The model the persistent store will handle.
    var model: [Entity] { get }
    
    /// Fetches the entity with the specified
    func get<entity: T>, withResourceID resourceID: String) throws -> T
    
    func create<T: Entity>(entity: T, initialValues: JSONObject?) throws
    
    func delete(entity entityName: String, resourceID: String)
    
    /// Returns the entity's values as a JSON object.
    var values: JSONObject { get }
    
    /// Attempts to sets the JSON values. Returns false for invalid data
    func setValues(values: JSONObject) -> Bool
}