//
//  Error.swift
//  
//
//  Created by Alsey Coleman Miller on 8/16/23.
//

import Foundation

/// CoreModel Error
public enum CoreModelError: Error {
    
    /// Invalid or unknown entity
    case invalidEntity(EntityName)
}
