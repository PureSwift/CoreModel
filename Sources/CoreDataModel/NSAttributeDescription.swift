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
    
    convenience init(
        attribute: Attribute,
        isOptional: Bool = true
    ) {
        self.init()
        self.name = attribute.id.rawValue
        self.isOptional = isOptional
        self.attributeType = .init(attributeType: attribute.type)
    }
}

#endif
