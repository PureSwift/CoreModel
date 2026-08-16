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

internal extension NSAttributeType {

    /// `NSCompositeAttributeType` (2100).
    ///
    /// - Note: Spelled by raw value so that referencing it doesn't depend on the
    /// availability annotations of the imported enum case. The
    /// `NSCompositeAttributeDescription` *class* still requires macOS 14 / iOS 17.
    static var composite: NSAttributeType { NSAttributeType(rawValue: 2100)! }
}

public extension NSAttributeType {

    init(attributeType: AttributeType) {
        switch attributeType {
        case .composite:
            self = .composite
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

    /// Reconstruct the CoreModel attribute type from a CoreData attribute description,
    /// including composite attributes and their (possibly nested) elements.
    ///
    /// Prefer this over ``init(attributeType:)``, which cannot represent composites:
    /// the elements live on the description, not on the `NSAttributeType`.
    init?(attribute: NSAttributeDescription) {
        guard attribute.attributeType == .composite else {
            guard let type = AttributeType(attributeType: attribute.attributeType) else {
                return nil
            }
            self = type
            return
        }
        guard #available(macOS 14, iOS 17, tvOS 17, watchOS 10, *) else {
            return nil
        }
        guard let composite = attribute as? NSCompositeAttributeDescription else {
            return nil
        }
        var elements = [Attribute]()
        elements.reserveCapacity(composite.elements.count)
        for element in composite.elements {
            // recursion handles nested composites
            guard let type = AttributeType(attribute: element) else {
                return nil
            }
            elements.append(Attribute(id: PropertyKey(rawValue: element.name), type: type))
        }
        self = .composite(elements)
    }

    /// - Note: Returns `nil` for `.compositeAttributeType`, whose elements cannot be
    /// recovered from the type alone. Use ``init(attribute:)`` to round-trip composites.
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
