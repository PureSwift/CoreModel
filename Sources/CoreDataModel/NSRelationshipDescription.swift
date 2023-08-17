//
//  NSRelationshipDescription.swift
//  
//
//  Created by Alsey Coleman Miller on 8/17/23.
//

#if canImport(CoreData)
import Foundation
import CoreData
import CoreModel

public extension NSRelationshipDescription {
    
    convenience init(relationship: Relationship) {
        self.init()
        self.isOrdered = true
        let toMany = relationship.type == .toMany
        assert(self.isToMany == toMany)
    }
}

#endif
