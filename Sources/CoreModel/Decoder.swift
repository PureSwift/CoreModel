//
//  Decoder.swift
//  
//
//  Created by Alsey Coleman Miller on 8/18/23.
//

import Foundation

// MARK: - Default Codable Implementation

extension Entity where Self: Decodable, Self.ID: Decodable {
    
    public init(
        from model: ModelData
    ) throws {
        try self.init(from: model, log: nil)
    }
    
    internal init(
        from model: ModelData,
        userInfo: [CodingUserInfoKey : Any] = [:],
        log: ((String) -> ())?
    ) throws {
        let idKey = (userInfo[.identifierCodingKey] as? Self.CodingKeys)?.stringValue ?? "id"
        let entity = EntityDescription(entity: Self.self)
        let decoder = ModelDataDecoder(
            referencing: model,
            entity: entity,
            identifierKey: idKey,
            userInfo: userInfo,
            log: log
        )
        try self.init(from: decoder)
    }
}

internal final class ModelDataDecoder: Decoder {
    
    // MARK: - Properties
    
    /// The path of coding keys taken to get to this point in decoding.
    fileprivate(set) var codingPath: [CodingKey]
    
    /// Any contextual information set by the user for decoding.
    let userInfo: [CodingUserInfoKey : Any]
    
    /// Logger
    var log: ((String) -> ())?
    
    /// Container to decode.
    let data: ModelData
    
    /// Property name of identifier
    let identifierKey: String
    
    let attributes: [PropertyKey: Attribute]
    
    let relationships: [PropertyKey: Relationship]
    
    // MARK: - Initialization
    
    fileprivate init(referencing data: ModelData,
                     entity: EntityDescription,
                     identifierKey: String,
                     at codingPath: [CodingKey] = [],
                     userInfo: [CodingUserInfoKey : Any],
                     log: ((String) -> ())?) {
        
        self.data = data
        self.codingPath = codingPath
        self.userInfo = userInfo
        self.log = log
        assert(data.entity == entity.id)
        
        // properties cache
        var attributes = [PropertyKey: Attribute]()
        attributes.reserveCapacity(entity.attributes.count)
        for attribute in entity.attributes {
            attributes[attribute.id] = attribute
        }
        self.attributes = attributes //.init(grouping: entity.attributes, by: { $0.id })
        var relationships = [PropertyKey: Relationship]()
        relationships.reserveCapacity(entity.relationships.count)
        for relationship in entity.relationships {
            relationships[relationship.id] = relationship
        }
        self.relationships = relationships //.init(grouping: entity.relationships, by: { $0.id })
    }
    
    // MARK: - Methods
    
    func container <Key: CodingKey> (keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        log?("Requested container keyed by \(type.sanitizedName) for path \"\(codingPath.path)\"")
        guard codingPath.isEmpty else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Can only decode root data with keyed container."))
        }
        let container = ModelDataKeyedDecodingContainer<Key>(referencing: self)
        return KeyedDecodingContainer(container)
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        log?("Requested unkeyed container for path \"\(codingPath.path)\"")
        guard codingPath.isEmpty == false else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Can not decode root data with unkeyed container."))
        }
        let container = try ModelDataUnkeyedDecodingContainer(referencing: self)
        return container
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        log?("Requested single value container for path \"\(codingPath.path)\"")
        guard codingPath.isEmpty == false else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Can not decode root data with single value container."))
        }
        let container = ModelDataSingleValueDecodingContainer(referencing: self)
        return container
    }
}

internal extension ModelDataDecoder {
    
    func decodeNil(forKey key: CodingKey) throws -> Bool {
        log?("Check if nil at path \"\(codingPath.path)\"")
        let property = PropertyKey(key)
        if let value = self.data.attributes[property] {
            return value == .null
        } else if let value = self.data.relationships[property] {
            return value == .null
        } else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode nil for non-existent property \"\(key.stringValue)\""))
        }
    }
    
    func decodeAttribute<T: AttributeDecodable>(_ type: T.Type, forKey key: CodingKey) throws -> T {
        log?("Will decode \(type) at path \"\(codingPath.path)\"")
        let property = PropertyKey(key)
        guard let attribute = self.data.attributes[property] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode \(type) for non-existent property \"\(key.stringValue)\""))
        }
        guard let value = T.init(attributeValue: attribute) else {
            throw DecodingError.typeMismatch(T.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode \(type) from \(attribute) for \"\(key.stringValue)\""))
        }
        return value
    }
    
    func decodeString(forKey key: CodingKey) throws -> String {
        log?("Will decode \(String.self) at path \"\(codingPath.path)\"")
        let property = PropertyKey(key)
        // determine if objectID, attribute or relationship
        if key.stringValue == identifierKey {
            return self.data.id.rawValue
        } else if let attribute = self.data.attributes[property] {
            guard let value = String.init(attributeValue: attribute) else {
                throw DecodingError.typeMismatch(String.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode \(String.self) from \(attribute) for \"\(key.stringValue)\""))
            }
            return value
        } else if let relationship = self.data.relationships[property] {
            guard case let .toOne(objectID) = relationship else {
                throw DecodingError.typeMismatch(String.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode \(String.self) from \(relationship) for \"\(key.stringValue)\""))
            }
            return objectID.rawValue
        } else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode \(String.self) for non-existent property \"\(key.stringValue)\""))
        }
    }
    
    func decodeNumeric <T: AttributeDecodable & FixedWidthInteger> (_ type: T.Type, forKey key: CodingKey) throws -> T {
        // Just default to attribute implementation for now
        try decodeAttribute(type, forKey: key)
    }
    
    func decodeDouble(forKey key: CodingKey) throws -> Double {
        // Just default to attribute implementation for now
        try decodeAttribute(Double.self, forKey: key)
    }
    
    func decodeFloat(forKey key: CodingKey) throws -> Float {
        // Just default to attribute implementation for now
        try decodeAttribute(Float.self, forKey: key)
    }
    
    func decodeDecodable<T: Decodable> (_ type: T.Type, forKey key: CodingKey) throws -> T {
        log?("Will decode \type) at path \"\(codingPath.path)\"")
        // override for native types
        if type == Data.self {
            return try decodeAttribute(Data.self, forKey: key) as! T
        } else if type == Date.self {
            return try decodeAttribute(Date.self, forKey: key) as! T
        } else if type == UUID.self {
            return try decodeAttribute(UUID.self, forKey: key) as! T
        } else if type == URL.self {
            return try decodeAttribute(URL.self, forKey: key) as! T
        } else if let decodableType = type as? AttributeDecodable.Type {
            return try decodeAttribute(decodableType, forKey: key) as! T
        } else {
            // decode using Decodable, container should read directly.
            return try T.init(from: self)
        }
    }
}

// MARK: - KeyedDecodingContainer

internal struct ModelDataKeyedDecodingContainer <K: CodingKey> : KeyedDecodingContainerProtocol {
    
    typealias Key = K
    
    // MARK: Properties
    
    /// A reference to the encoder we're reading from.
    let decoder: ModelDataDecoder
    
    /// The path of coding keys taken to get to this point in decoding.
    let codingPath: [CodingKey]
    
    /// All the keys the Decoder has for this container.
    let allKeys: [Key]
    
    // MARK: Initialization
    
    /// Initializes `self` by referencing the given decoder and container.
    init(referencing decoder: ModelDataDecoder) {
        assert(decoder.codingPath.isEmpty)
        self.decoder = decoder
        self.codingPath = decoder.codingPath
        // set keys
        var keys = [Key]()
        keys += decoder.data.relationships.keys
            .compactMap { Key(stringValue: $0.rawValue) }
        keys += decoder.data.attributes.keys
            .compactMap { Key(stringValue: $0.rawValue) }
        if let idKey = Key(stringValue: decoder.identifierKey) {
            keys.append(idKey)
        }
        self.allKeys = keys
    }
    
    // MARK: KeyedDecodingContainer Protocol
    
    func contains(_ key: Key) -> Bool {
        self.decoder.log?("Check whether key \"\(key.stringValue)\" exists")
        return allKeys.contains(where: { key.stringValue == $0.stringValue })
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        
        // set coding key context
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        return try decoder.decodeNil(forKey: key)
    }
    
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        return try decodeAttribute(type, forKey: key)
    }
    
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        return try decodeNumeric(type, forKey: key)
    }
    
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        return try decodeNumeric(type, forKey: key)
    }
    
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        return try decodeNumeric(type, forKey: key)
    }
    
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        return try decodeNumeric(type, forKey: key)
    }
    
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        return try decodeNumeric(type, forKey: key)
    }
    
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        try decodeNumeric(type, forKey: key)
    }
    
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        return try decodeNumeric(type, forKey: key)
    }
    
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        return try decodeNumeric(type, forKey: key)
    }
    
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        return try decodeNumeric(type, forKey: key)
    }
    
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        return try decodeNumeric(type, forKey: key)
    }
    
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        return try decoder.decodeFloat(forKey: key)
    }
    
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        return try decoder.decodeDouble(forKey: key)
    }
    
    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        self.decoder.log?("Will read \(type) at path \"\(decoder.codingPath.path)\"")
        return try self.decoder.decodeString(forKey: key)
    }
    
    func decode <T: Decodable> (_ type: T.Type, forKey key: Key) throws -> T {
        
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        self.decoder.log?("Will read \(type) at path \"\(decoder.codingPath.path)\"")
        return try self.decoder.decodeDecodable(type, forKey: key)
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError()
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        fatalError()
    }
    
    func superDecoder() throws -> Decoder {
        fatalError()
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        fatalError()
    }
    
    // MARK: Private Methods
    
    /// Decode native value type from CoreModel data.
    private func decodeAttribute <T: AttributeDecodable> (_ type: T.Type, forKey key: Key) throws -> T {
        
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        return try self.decoder.decodeAttribute(type, forKey: key)
    }
    
    private func decodeNumeric <T: AttributeDecodable & FixedWidthInteger> (_ type: T.Type, forKey key: Key) throws -> T {
        
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        return try self.decoder.decodeNumeric(type, forKey: key)
    }
}

// MARK: - SingleValueDecodingContainer

internal struct ModelDataSingleValueDecodingContainer: SingleValueDecodingContainer {
    
    // MARK: Properties
    
    /// A reference to the decoder we're reading from.
    let decoder: ModelDataDecoder
    
    /// The path of coding keys taken to get to this point in decoding.
    let codingPath: [CodingKey]
    
    // MARK: Initialization
    
    /// Initializes `self` by referencing the given decoder and container.
    init(referencing decoder: ModelDataDecoder) {
        assert(decoder.codingPath.isEmpty == false)
        self.decoder = decoder
        self.codingPath = decoder.codingPath
    }
    
    // MARK: SingleValueDecodingContainer Protocol
    
    func decodeNil() -> Bool {
        do {
            let key = try propertyKey()
            return try decoder.decodeNil(forKey: key)
        } catch {
            return true
        }
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        let key = try propertyKey()
        return try decoder.decodeAttribute(type, forKey: key)
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        let key = try propertyKey()
        return try decoder.decodeNumeric(type, forKey: key)
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        let key = try propertyKey()
        return try decoder.decodeNumeric(type, forKey: key)
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        let key = try propertyKey()
        return try decoder.decodeNumeric(type, forKey: key)
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        let key = try propertyKey()
        return try decoder.decodeNumeric(type, forKey: key)
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        let key = try propertyKey()
        return try decoder.decodeNumeric(type, forKey: key)
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        let key = try propertyKey()
        return try decoder.decodeNumeric(type, forKey: key)
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        let key = try propertyKey()
        return try decoder.decodeNumeric(type, forKey: key)
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        let key = try propertyKey()
        return try decoder.decodeNumeric(type, forKey: key)
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        let key = try propertyKey()
        return try decoder.decodeNumeric(type, forKey: key)
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        let key = try propertyKey()
        return try decoder.decodeNumeric(type, forKey: key)
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        let key = try propertyKey()
        return try decoder.decodeFloat(forKey: key)
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        let key = try propertyKey()
        return try decoder.decodeDouble(forKey: key)
    }
    
    func decode(_ type: String.Type) throws -> String {
        let key = try propertyKey()
        return try decoder.decodeString(forKey: key)
    }
    
    func decode <T : Decodable> (_ type: T.Type) throws -> T {
        let key = try propertyKey()
        return try decoder.decodeDecodable(type, forKey: key)
    }
    
    // MARK: Private Methods
    
    private func propertyKey() throws -> CodingKey {
        guard let key = codingPath.first else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode single value from root data."))
        }
        return key
    }
}
