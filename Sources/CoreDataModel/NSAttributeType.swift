//
//  NSAttributeType.swift
//  
//
//  Created by Alsey Coleman Miller on 8/17/23.
//

#if canImport(CoreData)
import Foundation
import CoreData
import CoreModel

public extension NSAttributeType {
    
    init(attributeType: AttributeType) {
        switch attributeType {
        case .bool:
            self = .booleanAttributeType
        case .int16:
            self = .integer16AttributeType
        case .int32:
            self = .integer32AttributeType
        case .int64:
            self = .integer64AttributeType
        case .float:
            self = .floatAttributeType
        case .double:
            self = .doubleAttributeType
        case .string:
            self = .stringAttributeType
        case .data:
            self = .binaryDataAttributeType
        case .date:
            self = .dateAttributeType
        case .uuid:
            self = .UUIDAttributeType
        case .url:
            self = .URIAttributeType
        case .decimal:
            self = .decimalAttributeType
        }
    }
}

public extension AttributeType {
    
    init?(attributeType: NSAttributeType) {
        switch attributeType {
        case .undefinedAttributeType:
            return nil
        case .integer16AttributeType:
            self = .int16
        case .integer32AttributeType:
            self = .int32
        case .integer64AttributeType:
            self = .int64
        case .decimalAttributeType:
            self = .decimal
        case .doubleAttributeType:
            self = .double
        case .floatAttributeType:
            self = .float
        case .stringAttributeType:
            self = .string
        case .booleanAttributeType:
            self = .bool
        case .dateAttributeType:
            self = .date
        case .binaryDataAttributeType:
            self = .data
        case .UUIDAttributeType:
            self = .uuid
        case .URIAttributeType:
            self = .url
        case .transformableAttributeType:
            return nil
        case .objectIDAttributeType:
            return nil
        #if swift(>=5.9)
        case .compositeAttributeType:
            return nil
        #endif
        @unknown default:
            return nil
        }
    }
}

#endif
