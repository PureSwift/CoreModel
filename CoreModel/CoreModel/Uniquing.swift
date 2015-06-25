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
    
    case String(StringAlias)
    
    case Integer(UInt)
}