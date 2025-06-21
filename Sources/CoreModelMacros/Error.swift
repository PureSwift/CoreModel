//
//  Error.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/17/25.
//

import Foundation

enum MacroError: Error {
    
    /// The provided type is invalid.
    case invalidType
    
    /// Unknown attribute type
    case unknownAttributeType(for: String)
    
    /// Unknown inverse relationship
    case unknownInverseRelationship(for: String)
}

#if canImport(Darwin)
extension MacroError: LocalizedError {
    
    var errorDescription: String? {
        switch self {
        case .invalidType:
            return NSLocalizedString("The provided type is invalid.", comment: "Invalid type error")
        case .unknownAttributeType(let type):
            return String(format: NSLocalizedString("Unknown attribute type: %@", comment: "Unknown attribute type error"), type)
        case .unknownInverseRelationship(let relationship):
            return String(format: NSLocalizedString("Unknown inverse relationship for: %@", comment: "Unknown inverse relationship error"), relationship)
        }
    }
}
#endif
