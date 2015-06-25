//
//  Property.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public protocol Property: JSONCodable {
    
    var name: String { get }
    
    var optional: Bool { get }
    
    var propertyType: PropertyType { get }
}

internal enum PropertyJSONKey: String {
    
    case name = "name"
    case optional = "optional"
    case propertyType = "propertyType"
}