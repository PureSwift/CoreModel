//
//  CoreDataModelError.swift
//  CoreDataModel
//
//  Created by Alsey Coleman Miller on 8/16/26.
//

#if canImport(CoreData)
import Foundation
import CoreModel

/// An error building a CoreData model from a CoreModel ``Model``.
public enum CoreDataModelError: Error {

    /// The model declares a composite attribute, which requires
    /// macOS 14, iOS 17, tvOS 17, or watchOS 10 or later.
    case compositeAttributesUnavailable(EntityName, PropertyKey)

    /// A composite attribute declared no elements.
    ///
    /// CoreData rejects a composite type with an empty element list.
    case emptyCompositeAttribute(PropertyKey)

    /// The stored value for a composite attribute did not match its element descriptions.
    case invalidCompositeValue(PropertyKey)
}

// MARK: - CustomNSError

extension CoreDataModelError: CustomNSError {

    public static var errorDomain: String { "org.pureswift.CoreDataModel.CoreDataModelError" }

    public var errorCode: Int {
        switch self {
        case .compositeAttributesUnavailable:   return 1
        case .emptyCompositeAttribute:          return 2
        case .invalidCompositeValue:            return 3
        }
    }

    public var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: description]
    }
}

// MARK: - CustomStringConvertible

extension CoreDataModelError: CustomStringConvertible {

    public var description: String {
        switch self {
        case let .compositeAttributesUnavailable(entity, key):
            return "Composite attribute \(entity).\(key) requires macOS 14, iOS 17, tvOS 17, or watchOS 10 or later."
        case let .emptyCompositeAttribute(key):
            return "Composite attribute \(key) must declare at least one element."
        case let .invalidCompositeValue(key):
            return "Invalid value for composite attribute \(key)."
        }
    }
}

#endif
