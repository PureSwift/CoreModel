//
//  Uniquing.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/25/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public protocol Uniquing {
    
    var uniqueIdentifier: UniqueIdentifier { get }
}

public enum UniqueIdentifier {
    
    /** Compiler error. */
    // case String(String)
    
    case Integer(UInt)
}