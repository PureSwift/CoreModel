//
//  Encodable.swift
//  
//
//  Created by Alsey Coleman Miller on 8/17/23.
//

import Foundation

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
    
    mutating func encodeRelationship<T, K>(_ value: [T], forKey key: K) where T: CustomStringConvertible, K: CodingKey {
        
        let property = PropertyKey(key)
        let objectIDs = value.map { ObjectID(rawValue: $0.description) }
        self.relationships[property] = .toMany(objectIDs)
    }
}

extension Entity where Self: Encodable, Self.ID: Encodable {
    
    // TODO: Default implementation for Encodable
}

public extension ModelStorage {
    
    /// Create or edit a managed object.
    func insert<T>(_ value: T) async throws where T: Entity, T: Encodable {
        let model = value.encode()
        try await insert(model)
    }
}

public protocol AttributeEncodable {
    
    var attributeValue: AttributeValue { get }
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
