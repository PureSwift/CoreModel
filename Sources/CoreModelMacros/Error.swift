//
//  Error.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/17/25.
//

enum MacroError: Error {
    
    case invalidType
    case unknownAttributeType(for: String)
}
