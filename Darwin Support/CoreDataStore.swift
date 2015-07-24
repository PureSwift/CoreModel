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
    
    // MARK: - Initialization
    
    public init(managedObjectContext: NSManagedObjectContext) {
        
        self.managedObjectContext = managedObjectContext
    }
    
    // MARK: - Store
    
    public lazy var model: [Entity] = {  }()
    
    public func exists(resource: Resource) throws -> Bool {
        
        
    }
    
    
}

// MARK: - CoreData Extensions



// MARK: - Model Conversion
