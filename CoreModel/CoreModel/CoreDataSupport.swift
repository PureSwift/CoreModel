//
//  CoreDataSupport.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

public extension NSFetchRequest {
    
    func toSearchRequest<T: ManagedObject>() -> SearchRequest<T>? {
        
        return nil
    }
}

/*
 extension NSManagedObjectContext: Context {
    
    public var model: Model {
        
        return self.persistentStoreCoordinator!.managedObjectModel
    }
}

extension NSManagedObjectModel: Model {
    
    
}

extension NSEntityDescription: Entity {
    
    
}

extension NSPropertyDescription: Property {
    
    
}
*/