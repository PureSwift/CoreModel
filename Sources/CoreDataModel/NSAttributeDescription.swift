//
//  NSAttributeDescription.swift
//
//
//  Created by Alsey Coleman Miller on 8/17/23.
//

#if canImport(CoreData)
import Foundation
import CoreData
import CoreModel

public extension NSAttributeDescription {

    /// - Warning: A composite attribute needs an `NSCompositeAttributeDescription`,
    /// which this initializer cannot return. Use ``make(attribute:isOptional:)`` instead.
    convenience init(
        attribute: Attribute,
        isOptional: Bool = true
    ) {
        self.init()
        self.name = attribute.id.rawValue
        self.isOptional = isOptional
        assert(attribute.type.isComposite == false, "Use NSAttributeDescription.make(attribute:) for composite attributes")
        self.attributeType = .init(attributeType: attribute.type)
    }
}

internal extension NSAttributeDescription {

    /// Build the CoreData property description for a CoreModel attribute.
    ///
    /// A composite attribute produces an `NSCompositeAttributeDescription`, which is a
    /// different class and so cannot come from a `convenience init` on this one.
    ///
    /// - Note: CoreData's two other constraints on elements hold by construction here:
    /// an element can never be a relationship (``Attribute`` has no relationship type),
    /// and the element tree is a finite value, so it cannot be recursive.
    static func make(attribute: Attribute, isOptional: Bool = true) throws -> NSAttributeDescription {
        guard case let .composite(elements) = attribute.type else {
            return NSAttributeDescription(attribute: attribute, isOptional: isOptional)
        }
        guard elements.isEmpty == false else {
            throw CoreDataModelError.emptyCompositeAttribute(attribute.id)
        }
        guard #available(macOS 14, iOS 17, tvOS 17, watchOS 10, *) else {
            throw CoreDataModelError.compositeAttributesUnavailable("", attribute.id)
        }
        let description = NSCompositeAttributeDescription()
        description.name = attribute.id.rawValue
        description.isOptional = isOptional
        description.attributeType = .composite
        // - Note: Elements are always optional. CoreData raises a "missing mandatory
        //   data" validation fault on save when a non-optional element is absent, and
        //   `momc` does not diagnose it at build time.
        var children = [NSAttributeDescription]()
        children.reserveCapacity(elements.count)
        for element in elements {
            children.append(try make(attribute: element, isOptional: true))
        }
        description.elements = children
        return description
    }
}

#endif
