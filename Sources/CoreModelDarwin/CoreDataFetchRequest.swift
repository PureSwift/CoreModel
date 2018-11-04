//
//  CoreDataFetchRequest.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/27/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import Foundation
import CoreData

public extension NSFetchRequest {
    
    convenience init(fetchRequest: FetchRequest, store: CoreDataStore) throws {
        
        self.init(entityName: fetchRequest.entityName)
        
        if let predicate = fetchRequest.predicate {
            
            self.predicate = try predicate.toPredicate(forFetchRequest: fetchRequest, store: store)
        }
        
        self.fetchLimit = Int(fetchRequest.fetchLimit)
        
        self.fetchOffset = Int(fetchRequest.fetchOffset)
        
        var sortDescriptors = [NSSortDescriptor]()
        
        for sortDescriptor in fetchRequest.sortDescriptors {
            
            sortDescriptors.append(NSSortDescriptor(key: sortDescriptor.propertyName, ascending: sortDescriptor.ascending))
        }
        
        self.sortDescriptors = sortDescriptors
    }
}
