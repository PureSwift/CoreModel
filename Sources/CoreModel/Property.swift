//
//  Property.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

/// CoreModel Property
public protocol Property {
    
    associatedtype PropertyType
    
    var id: PropertyKey { get }
    
    var type: PropertyType { get }
}
