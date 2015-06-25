//
//  Property.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public protocol Property {
    
    var name: String { get }
    
    var optional: Bool { get }
}

public extension Property {
    
    var optional: Bool {
        
        return false
    }
}