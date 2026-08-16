//
//  Decodable.swift
//  
//
//  Created by Alsey Coleman Miller on 8/17/23.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

// MARK: - ModelData Decoding

public extension ModelData {

    func decode<T, K>(_ type: T.Type, forKey key: K) throws(ModelDataDecodingError) -> T where T: AttributeDecodable, K: CodingKey {

        let property = PropertyKey(key)
        guard let attribute = self.attributes[property] else {
            throw coreModelKeyNotFoundError(key)
        }
        // TODO: Optional values
        /*
        guard attribute != .null else {
            return
        }*/
        guard let decodable = type.init(attributeValue: attribute) else {
            throw coreModelTypeMismatchError(type, forKey: key, from: attribute)
        }
        return decodable
    }

    func decodeRelationship<T, K>(_ type: T.Type, forKey key: K) throws(ModelDataDecodingError) -> T where T: ObjectIDConvertible, K: CodingKey {

        let property = PropertyKey(key)
        guard let relationship = self.relationships[property] else {
            throw coreModelKeyNotFoundError(key)
        }
        switch relationship {
        case .null:
            throw coreModelKeyNotFoundError(key)
        case .toMany:
            throw coreModelTypeMismatchError(type, forKey: key, from: relationship)
        case let .toOne(objectID):
            guard let id = type.init(objectID: objectID) else {
                throw coreModelInvalidIdentifierError(objectID)
            }
            return id
        }
    }

    func decodeRelationship<T, K>(_ type: T?.Type, forKey key: K) throws(ModelDataDecodingError) -> T? where T: ObjectIDConvertible, K: CodingKey {

        let property = PropertyKey(key)
        guard let relationship = self.relationships[property] else {
            return nil
        }
        switch relationship {
        case .null:
            return nil
        case .toMany:
            throw coreModelTypeMismatchError(type, forKey: key, from: relationship)
        case let .toOne(objectID):
            guard let id = T.init(objectID: objectID) else {
                throw coreModelInvalidIdentifierError(objectID)
            }
            return id
        }
    }

    func decodeRelationship<T, K>(_ type: [T].Type, forKey key: K) throws(ModelDataDecodingError) -> [T] where T: ObjectIDConvertible, K: CodingKey {

        let property = PropertyKey(key)
        guard let relationship = self.relationships[property] else {
            throw coreModelKeyNotFoundError(key)
        }
        switch relationship {
        case .null:
            return []
        case .toOne:
            throw coreModelTypeMismatchError(type, forKey: key, from: relationship)
        case let .toMany(objectIDs):
            // - Note: An explicit loop rather than `objectIDs.map`, because the
            //   `rethrows` closure overload erases the thrown error back to
            //   `any Error`, which cannot convert to the typed `throws` clause
            //   under Embedded Swift.
            var ids = [T]()
            ids.reserveCapacity(objectIDs.count)
            for objectID in objectIDs {
                guard let id = T.init(objectID: objectID) else {
                    throw coreModelInvalidIdentifierError(objectID)
                }
                ids.append(id)
            }
            return ids
        }
    }
}

// MARK: - Composite Attribute Value Decoding

public extension Dictionary where Key == PropertyKey, Value == AttributeValue {

    /// Decode an element of a composite attribute value.
    ///
    /// - Returns: `nil` when the element is absent, `.null`, or holds a value of a
    /// different type — the shape ``CompositeAttributeDecodable/init(compositeValue:)``
    /// needs, since it is failable rather than throwing.
    func decode<T, K>(_ type: T.Type, forKey key: K) -> T? where T: AttributeDecodable, K: CodingKey {

        let property = PropertyKey(key)
        guard let value = self[property] else {
            return nil
        }
        return T.init(attributeValue: value)
    }
}

// MARK: - AttributeDecodable

public protocol AttributeDecodable {

    init?(attributeValue: AttributeValue)
}

// MARK: - CompositeAttributeDecodable

/// A type that can be loaded from the value of a composite attribute.
///
/// - Note: A type that is both `CompositeAttributeDecodable` and `RawRepresentable`
/// where `RawValue: AttributeDecodable` inherits two candidate default implementations
/// of `init(attributeValue:)` and will not compile. Implement `init(attributeValue:)`
/// explicitly in that case.
public protocol CompositeAttributeDecodable: CompositeAttribute, AttributeDecodable {

    /// Initialize from the value of each element, keyed by its ``Attribute/id``.
    init?(compositeValue: [PropertyKey: AttributeValue])
}

public extension CompositeAttributeDecodable {

    init?(attributeValue: AttributeValue) {
        guard case let .composite(elements) = attributeValue else {
            return nil
        }
        self.init(compositeValue: elements)
    }
}

extension Optional: AttributeDecodable where Wrapped: AttributeDecodable {
    
    public init?(attributeValue: AttributeValue) {
        switch attributeValue {
        case .null:
            self = .none
        default:
            guard let value = Wrapped.init(attributeValue: attributeValue) else {
                return nil
            }
            self = .some(value)
        }
    }
}

extension AttributeDecodable where Self: RawRepresentable, RawValue: AttributeDecodable {
    
    public init?(attributeValue: AttributeValue) {
        guard let rawValue = RawValue.init(attributeValue: attributeValue) else {
            return nil
        }
        self.init(rawValue: rawValue)
    }
}

extension Bool: AttributeDecodable {
    
    public init?(attributeValue: AttributeValue) {
        guard case let .bool(value) = attributeValue else {
            return nil
        }
        self = value
    }
}

extension String: AttributeDecodable {
    
    public init?(attributeValue: AttributeValue) {
        guard case let .string(value) = attributeValue else {
            return nil
        }
        self = value
    }
}

extension UUID: AttributeDecodable {
    
    public init?(attributeValue: AttributeValue) {
        guard case let .uuid(value) = attributeValue else {
            return nil
        }
        self = value
    }
}

extension URL: AttributeDecodable {
    
    public init?(attributeValue: AttributeValue) {
        guard case let .url(value) = attributeValue else {
            return nil
        }
        self = value
    }
}

extension Date: AttributeDecodable {
    
    public init?(attributeValue: AttributeValue) {
        guard case let .date(value) = attributeValue else {
            return nil
        }
        self = value
    }
}

extension Data: AttributeDecodable {
    
    public init?(attributeValue: AttributeValue) {
        guard case let .data(value) = attributeValue else {
            return nil
        }
        self = value
    }
}

extension Decimal: AttributeDecodable {
    
    public init?(attributeValue: AttributeValue) {
        guard case let .decimal(value) = attributeValue else {
            return nil
        }
        self = value
    }
}

extension Float: AttributeDecodable {
    
    public init?(attributeValue: AttributeValue) {
        guard case let .float(value) = attributeValue else {
            return nil
        }
        self = value
    }
}

extension Double: AttributeDecodable {
    
    public init?(attributeValue: AttributeValue) {
        guard case let .double(value) = attributeValue else {
            return nil
        }
        self = value
    }
}

extension Int: AttributeDecodable {
    
    public init?(attributeValue: AttributeValue) {
        switch attributeValue {
        case .null,
            .string,
            .uuid,
            .url,
            .data,
            .date,
            .bool,
            .decimal,
            .float,
            .double,
            .composite:
            return nil
        case let .int16(value):
            self = numericCast(value)
        case let .int32(value):
            self = numericCast(value)
        case let .int64(value):
            self = numericCast(value)
        }
    }
}

extension Int8: AttributeDecodable {
    
    public init?(attributeValue: AttributeValue) {
        switch attributeValue {
        case .null,
            .string,
            .uuid,
            .url,
            .data,
            .date,
            .bool,
            .decimal,
            .float,
            .double,
            .composite:
            return nil
        case let .int16(value):
            self = numericCast(value)
        case let .int32(value):
            self = numericCast(value)
        case let .int64(value):
            self = numericCast(value)
        }
    }
}

extension Int16: AttributeDecodable {
    
    public init?(attributeValue: AttributeValue) {
        switch attributeValue {
        case .null,
            .string,
            .uuid,
            .url,
            .data,
            .date,
            .bool,
            .decimal,
            .float,
            .double,
            .composite:
            return nil
        case let .int16(value):
            self = value
        case let .int32(value):
            self = numericCast(value)
        case let .int64(value):
            self = numericCast(value)
        }
    }
}

extension Int32: AttributeDecodable {
    
    public init?(attributeValue: AttributeValue) {
        switch attributeValue {
        case .null,
            .string,
            .uuid,
            .url,
            .data,
            .date,
            .bool,
            .decimal,
            .float,
            .double,
            .composite:
            return nil
        case let .int16(value):
            self = numericCast(value)
        case let .int32(value):
            self = value
        case let .int64(value):
            self = numericCast(value)
        }
    }
}

extension Int64: AttributeDecodable {
    
    public init?(attributeValue: AttributeValue) {
        switch attributeValue {
        case .null,
            .string,
            .uuid,
            .url,
            .data,
            .date,
            .bool,
            .decimal,
            .float,
            .double,
            .composite:
            return nil
        case let .int16(value):
            self = numericCast(value)
        case let .int32(value):
            self = numericCast(value)
        case let .int64(value):
            self = value
        }
    }
}

extension UInt: AttributeDecodable {
    
    public init?(attributeValue: AttributeValue) {
        switch attributeValue {
        case .null,
            .string,
            .uuid,
            .url,
            .data,
            .date,
            .bool,
            .decimal,
            .float,
            .double,
            .composite:
            return nil
        case let .int16(value):
            self = numericCast(value)
        case let .int32(value):
            self = numericCast(value)
        case let .int64(value):
            self = numericCast(value)
        }
    }
}


extension UInt8: AttributeDecodable {
    
    public init?(attributeValue: AttributeValue) {
        switch attributeValue {
        case .null,
            .string,
            .uuid,
            .url,
            .data,
            .date,
            .bool,
            .decimal,
            .float,
            .double,
            .composite:
            return nil
        case let .int16(value):
            self = numericCast(value)
        case let .int32(value):
            self = numericCast(value)
        case let .int64(value):
            self = numericCast(value)
        }
    }
}


extension UInt16: AttributeDecodable {
    
    public init?(attributeValue: AttributeValue) {
        switch attributeValue {
        case .null,
            .string,
            .uuid,
            .url,
            .data,
            .date,
            .bool,
            .decimal,
            .float,
            .double,
            .composite:
            return nil
        case let .int16(value):
            self = numericCast(value)
        case let .int32(value):
            self = numericCast(value)
        case let .int64(value):
            self = numericCast(value)
        }
    }
}


extension UInt32: AttributeDecodable {
    
    public init?(attributeValue: AttributeValue) {
        switch attributeValue {
        case .null,
            .string,
            .uuid,
            .url,
            .data,
            .date,
            .bool,
            .decimal,
            .float,
            .double,
            .composite:
            return nil
        case let .int16(value):
            self = numericCast(value)
        case let .int32(value):
            self = numericCast(value)
        case let .int64(value):
            self = numericCast(value)
        }
    }
}

extension UInt64: AttributeDecodable {
    
    public init?(attributeValue: AttributeValue) {
        switch attributeValue {
        case .null,
            .string,
            .uuid,
            .url,
            .data,
            .date,
            .bool,
            .decimal,
            .float,
            .double,
            .composite:
            return nil
        case let .int16(value):
            self = numericCast(value)
        case let .int32(value):
            self = numericCast(value)
        case let .int64(value):
            self = numericCast(value)
        }
    }
}
