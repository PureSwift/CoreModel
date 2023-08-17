//
//  NSAttributeDescription.swift
//  
//
//  Created by Alsey Coleman Miller on 8/17/23.
//

#if canImport(CoreData)
import Foundation
import CoreData
import CoreModel

public extension NSAttributeDescription {
    
    convenience init(attribute: Attribute) {
        self.init()
        self.attributeType = .init(attributeType: attribute.type)
    }
}

#endif
