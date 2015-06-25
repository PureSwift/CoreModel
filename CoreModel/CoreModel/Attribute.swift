//
//  Attribute.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public struct Attribute: Property {
    
    public let name: String
    
    public let optional: Bool
        
    public let attributeType: AttributeType
    
    public init(name: String, optional: Bool, attributeType: AttributeType) {
        
        self.name = name
        self.optional = optional
        self.attributeType = attributeType
    }
}