//
//  CoreDataExtensions.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/23/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

#if os(OSX)

import Foundation
import CoreData

public extension NSManagedObjectContext {
    
    /// Wraps the block to allow for error throwing.
    @available(OSX 10.7, *)
    func performErrorBlockAndWait(block: () throws -> Void) throws {
        
        var blockError: ErrorType?
        
        self.performBlockAndWait { () -> Void in
            
            do {
                try block()
            }
            catch {
                
                blockError = error
            }
        }
        
        if blockError != nil {
            
            throw blockError!
        }
        
        return
    }
}

public extension NSManagedObject {
    
    /// Get an array from a to-many relationship.
    func arrayValueForToManyRelationship(relationship key: String) -> [NSManagedObject]? {
        
        // assert relationship exists
        assert(self.entity.relationshipsByName[key] != nil, "Relationship \(key) doesnt exist on \(self.entity.name)")
        
        // get relationship
        let relationship = self.entity.relationshipsByName[key]!
        
        // assert that relationship is to-many
        assert(relationship.toMany, "Relationship \(key) on \(self.entity.name) is not to-many")
        
        let value: AnyObject? = self.valueForKey(key)
        
        if value == nil {
            
            return nil
        }
        
        // ordered set
        if relationship.ordered {
            
            let orderedSet = value as! NSOrderedSet
            
            return orderedSet.array as? [NSManagedObject]
        }
        
        // set
        let set = value as! NSSet
        
        return set.allObjects as? [NSManagedObject]
    }
    
    /// Wraps the ```-valueForKey:``` method in the context's queue.
    func valueForKey(key: String, managedObjectContext: NSManagedObjectContext) -> AnyObject? {
        
        var value: AnyObject?
        
        managedObjectContext.performBlockAndWait { () -> Void in
            
            value = self.valueForKey(key)
        }
        
        return value
    }
}

public extension NSPredicate {
    
    /// Transverses the predicate tree and returns all comparison predicates. 
    /// If this is called on an instance of ```NSComparisonPredicate```, then an array with self is returned.
    ///
    /// - note: Only use with concrete subclasses of ```NSPredicate```.
    func extractComparisonSubpredicates() -> [NSComparisonPredicate] {
        
        assert(self.dynamicType !== NSPredicate.self, "Cannot extract comparison subpredicates from NSPredicate, must use concrete subclasses")
        
        // main predicate is comparison predicate
        if let comparisonPredicate = self as? NSComparisonPredicate {
            
            return [comparisonPredicate]
        }
        
        let compoundPredicate = self as! NSCompoundPredicate
        
        let comparisonPredicates = NSMutableArray()
        
        for subpredicate in compoundPredicate.subpredicates as! [NSPredicate] {
            
            let subpredicates = subpredicate.extractComparisonSubpredicates()
            
            comparisonPredicates.addObjectsFromArray(subpredicates)
        }
        
        return (comparisonPredicates as NSArray) as! [NSComparisonPredicate]
    }
}

#endif

