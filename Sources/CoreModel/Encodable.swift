//
//  Encodable.swift
//  
//
//  Created by Alsey Coleman Miller on 8/17/23.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

// MARK: - ModelData Encoding

public extension ModelData {
    
    mutating func encode<T, K>(_ value: T, forKey key: K) where T: AttributeEncodable, K: CodingKey {
        
        let property = PropertyKey(key)
        self.attributes[property] = value.attributeValue
    }
    
    mutating func encodeRelationship<T, K>(_ value: T, forKey key: K) where T: CustomStringConvertible, K: CodingKey {

        let property = PropertyKey(key)
        let objectID = ObjectID(rawValue: value.description)
        self.relationships[property] = .toOne(objectID)
    }

    mutating func encodeRelationship<T, K>(_ value: T?, forKey key: K) where T: CustomStringConvertible, K: CodingKey {

        let property = PropertyKey(key)
        guard let value else {
            self.relationships[property] = .null
            return
        }
        let objectID = ObjectID(rawValue: value.description)
        self.relationships[property] = .toOne(objectID)
    }

    mutating func encodeRelationship<T, K>(_ value: [T], forKey key: K) where T: CustomStringConvertible, K: CodingKey {
        
        let property = PropertyKey(key)
        let objectIDs = value.map { ObjectID(rawValue: $0.description) }
        self.relationships[property] = .toMany(objectIDs)
    }
}

// MARK: - Composite Attribute Value Encoding

public extension Dictionary where Key == PropertyKey, Value == AttributeValue {

    /// Encode an element of a composite attribute value.
    mutating func encode<T, K>(_ value: T, forKey key: K) where T: AttributeEncodable, K: CodingKey {

        let property = PropertyKey(key)
        self[property] = value.attributeValue
    }
}

// MARK: - AttributeEncodable

public protocol AttributeEncodable {

    var attributeValue: AttributeValue { get }
}

// MARK: - CompositeAttribute

/// A type that describes the elements of the composite attribute it represents.
///
/// Modeled on CoreData's `NSCompositeAttributeDescription`. Conform to
/// ``CompositeAttributeEncodable``, ``CompositeAttributeDecodable``, or
/// ``CompositeAttributeCodable`` rather than to this protocol directly.
public protocol CompositeAttribute {

    /// The named sub-attributes this composite is made of.
    ///
    /// - Note: Elements are ``Attribute`` values and so can never be relationships.
    /// An element may itself be ``AttributeType/composite(_:)``.
    static var attributeElements: [Attribute] { get }
}

public extension CompositeAttribute {

    /// The attribute type describing this composite.
    static var attributeType: AttributeType { .composite(attributeElements) }
}

// MARK: - CompositeAttributeEncodable

/// A type that can be stored as the value of a composite attribute.
public protocol CompositeAttributeEncodable: CompositeAttribute, AttributeEncodable {

    /// The value of each element, keyed by its ``Attribute/id``.
    var compositeValue: [PropertyKey: AttributeValue] { get }
}

public extension CompositeAttributeEncodable {

    var attributeValue: AttributeValue { .composite(compositeValue) }
}

extension Optional: AttributeEncodable where Wrapped: AttributeEncodable {
    
    public var attributeValue: AttributeValue {
        switch self {
        case .none:
            return .null
        case .some(let wrapped):
            return wrapped.attributeValue
        }
    }
}

extension AttributeEncodable where Self: RawRepresentable, RawValue: AttributeEncodable {
    
    public var attributeValue: AttributeValue {
        rawValue.attributeValue
    }
}

extension Bool: AttributeEncodable {
    
    public var attributeValue: AttributeValue { .bool(self) }
}

extension Int: AttributeEncodable {
    
    public var attributeValue: AttributeValue { .int64(numericCast(self)) }
}

extension Int8: AttributeEncodable {
    
    public var attributeValue: AttributeValue { .int16(numericCast(self)) }
}

extension Int16: AttributeEncodable {
    
    public var attributeValue: AttributeValue { .int16(self) }
}

extension Int32: AttributeEncodable {
    
    public var attributeValue: AttributeValue { .int32(self) }
}

extension Int64: AttributeEncodable {
    
    public var attributeValue: AttributeValue { .int64(self) }
}

extension UInt: AttributeEncodable {
    
    public var attributeValue: AttributeValue { .int64(numericCast(self)) }
}

extension UInt8: AttributeEncodable {
    
    public var attributeValue: AttributeValue { .int16(numericCast(self)) }
}

extension UInt16: AttributeEncodable {
    
    public var attributeValue: AttributeValue { .int32(numericCast(self)) }
}

extension UInt32: AttributeEncodable {
    
    public var attributeValue: AttributeValue { .int64(numericCast(self)) }
}

extension UInt64: AttributeEncodable {
    
    public var attributeValue: AttributeValue { .int64(numericCast(self)) }
}

extension Float: AttributeEncodable {
    
    public var attributeValue: AttributeValue { .float(self) }
}

extension Double: AttributeEncodable {
    
    public var attributeValue: AttributeValue { .double(self) }
}

extension String: AttributeEncodable {
    
    public var attributeValue: AttributeValue { .string(self) }
}

extension Date: AttributeEncodable {
    
    public var attributeValue: AttributeValue { .date(self) }
}

extension Data: AttributeEncodable {
    
    public var attributeValue: AttributeValue { .data(self) }
}

extension UUID: AttributeEncodable {
    
    public var attributeValue: AttributeValue { .uuid(self) }
}

extension URL: AttributeEncodable {
    
    public var attributeValue: AttributeValue { .url(self) }
}

extension Decimal: AttributeEncodable {
    
    public var attributeValue: AttributeValue { .decimal(self) }
}
