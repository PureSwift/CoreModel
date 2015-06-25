//
//  Property.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public protocol Property: Hashable {
    
    var name: String { get }
    
    var optional: Bool { get }
}

public extension Property {
    
    var optional: Bool {
        
        return true
    }
    
    // MARK: - Hashable
    
    var hashValue: Int {
        
        return name.hashValue
    }
}