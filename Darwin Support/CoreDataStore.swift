//
//  CoreDataStore.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/23/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import Foundation
import CoreData

/// **CoreData**-backed **CoreModel** ```Store``` implementation.
public final class CoreDataStore: Store {
    
    // MARK: - Properties
    
    /// The managed object context this ```Store``` is backed by.
    public let managedObjectContext: NSManagedObjectContext
    
    /// Name of the attribute that all entities
    public let resourceIDAttributeName: String
    
    // MARK: - Initialization
    
    public init?(managedObjectContext: NSManagedObjectContext) {
        
        guard let model = managedObjectContext.persistentStoreCoordinator.managedObjectModel.toModel else { r
            
            return nil
        }
        
        self.model = model
        self.managedObjectContext = managedObjectContext
    }
    
    // MARK: - Store
    
    public let model: [Entity]
    
    public func exists(resource: Resource) throws -> Bool {
        
        
    }
    
    
}

// MARK: - CoreData Extensions



// MARK: - Model Conversion
