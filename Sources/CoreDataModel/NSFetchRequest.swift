//
//  NSFetchRequest.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/27/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

#if canImport(CoreData)
import Foundation
import CoreData
import CoreModel

public extension FetchRequest {
    
    func toFoundation() -> NSFetchRequest<NSManagedObject> {
        toFoundation(NSManagedObject.self)
    }
    
    func toFoundation<ResultType: NSFetchRequestResult>(_ result: ResultType.Type) -> NSFetchRequest<ResultType> {
        
        let fetchRequest = NSFetchRequest<ResultType>(entityName: entity.rawValue)
        fetchRequest.predicate = predicate?.toFoundation()
        fetchRequest.fetchLimit = fetchLimit
        var sortDescriptors = sortDescriptors.map {
            NSSortDescriptor(key: $0.property.rawValue, ascending: $0.ascending)
        }
        sortDescriptors.append(NSSortDescriptor(key: NSManagedObject.BuiltInProperty.id.rawValue, ascending: true))
        fetchRequest.sortDescriptors = sortDescriptors
        return fetchRequest
    }
}

#endif
