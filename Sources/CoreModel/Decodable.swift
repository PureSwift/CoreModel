//
//  Decodable.swift
//  
//
//  Created by Alsey Coleman Miller on 8/17/23.
//

import Foundation

// MARK: - ModelData Decoding

public extension ModelData {
    
    func decode<T, K>(_ type: T.Type, forKey key: K) throws -> T where T: AttributeDecodable, K: CodingKey {
        
        let property = PropertyKey(key)
        guard let attribute = self.attributes[property] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: [], debugDescription: "Key \(key.stringValue) not found"))
        }
        // TODO: Optional values
        /*
        guard attribute != .null else {
            return
        }*/
        guard let decodable = type.init(attributeValue: attribute) else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: [], debugDescription: "Cannot decode \(String(describing: type)) from \(attribute)"))
        }
        return decodable
    }
    
    func decodeRelationship<T, K>(_ type: T.Type, forKey key: K) throws -> T where T: ObjectIDConvertible, K: CodingKey {
        
        let property = PropertyKey(key)
        guard let relationship = self.relationships[property] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: [], debugDescription: "Key \(key.stringValue) not found"))
        }
        switch relationship {
        case .null:
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: [], debugDescription: "Key \(key.stringValue) not found"))
        case .toMany:
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: [], debugDescription: "Cannot decode \(String(describing: type)) from \(relationship)"))
        case let .toOne(objectID):
            guard let id = type.init(objectID: objectID) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Cannot decode identifier from \(objectID)"))
            }
            return id
        }
    }
    
    func decodeRelationship<T, K>(_ type: [T].Type, forKey key: K) throws -> [T] where T: ObjectIDConvertible, K: CodingKey {
        
        let property = PropertyKey(key)
        guard let relationship = self.relationships[property] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: [], debugDescription: "Key \(key.stringValue) not found"))
        }
        switch relationship {
        case .null:
            return []
        case .toOne:
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: [], debugDescription: "Cannot decode \(String(describing: type)) from \(relationship)"))
        case let .toMany(objectIDs):
            return try objectIDs.map {
                guard let id = T.init(objectID: $0) else {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Cannot decode identifier from \($0)"))
                }
                return id
            }
        }
    }
}

// MARK: - Default Codable Implementation

extension Entity where Self: Decodable, Self.ID: Decodable {
    
    // TODO: Default implementation for Decodable
}

// MARK: - AttributeDecodable

public protocol AttributeDecodable {
    
    init?(attributeValue: AttributeValue)
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
            .float,
            .double:
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
            .float,
            .double:
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
            .float,
            .double:
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
            .float,
            .double:
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
            .float,
            .double:
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
            .float,
            .double:
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
            .float,
            .double:
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
            .float,
            .double:
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
            .float,
            .double:
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
            .float,
            .double:
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
