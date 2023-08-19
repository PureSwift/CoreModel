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
        log: ((String) -> ())?,
        userInfo: [CodingUserInfoKey : Any] = [:]
    ) throws {
        let entity = EntityDescription(entity: Self.self)
        let decoder = ModelDataDecoder(
            referencing: model,
            entity: entity,
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
                     identifierKey: String = "id",
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
        let container = ModelDataKeyedDecodingContainer<Key>(referencing: self)
        return KeyedDecodingContainer(container)
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        
        log?("Requested unkeyed container for path \"\(codingPath.path)\"")
        let container = try ModelDataUnkeyedDecodingContainer(referencing: self)
        return container
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        
        log?("Requested single value container for path \"\(codingPath.path)\"")
        let container = ModelDataSingleValueDecodingContainer(referencing: self)
        return container
    }
}

fileprivate extension ModelDataDecoder {
    
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
    
    func decodeAttribute<T: AttributeDecodable>(_ type: T, forKey key: CodingKey) throws -> T {
        log?("Will decode \(type) at path \"\(codingPath.path)\"")
        
    }
    
    func decodeString(forKey key: CodingKey) throws -> String {
        return try readLengthPrefixString()
    }
    
    func decodeNumeric <T: AttributeDecodable & FixedWidthInteger> (_ type: T.Type, forKey key: CodingKey) throws -> T {
        let value = try read(type)
        return isLittleEndian ? T.init(littleEndian: value) : T.init(bigEndian: value)
    }
    
    func decodeDouble(_ data: Data) throws -> Double {
        let bitPattern = try readNumeric(UInt64.self)
        return Double(bitPattern: bitPattern)
    }
    
    func decodeFloat(_ data: Data) throws -> Float {
        let bitPattern = try readNumeric(UInt32.self)
        return Float(bitPattern: bitPattern)
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
        let value = try decodeNumeric(Int32.self, forKey: key)
        return Int(value)
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
        let value = try decodeNumeric(UInt32.self, forKey: key)
        return UInt(value)
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
        try decodeAttribute(type, forKey: key)
    }
    
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        try decodeAttribute(type, forKey: key)
    }
    
    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        self.decoder.log?("Will read \(type) at path \"\(decoder.codingPath.path)\"")
        return try self.decoder.readString()
    }
    
    func decode <T: Decodable> (_ type: T.Type, forKey key: Key) throws -> T {
        
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        self.decoder.log?("Will read \(type) at path \"\(decoder.codingPath.path)\"")
        return try self.decoder.readDecodable(T.self)
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
        self.decoder.log?("Will read \(T.self) at path \"\(decoder.codingPath.path)\"")
        return try self.decoder.read(T.self)
    }
    
    private func decodeNumeric <T: ModelDataRawDecodable & FixedWidthInteger> (_ type: T.Type, forKey key: Key) throws -> T {
        
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        self.decoder.log?("Will read \(T.self) at path \"\(decoder.codingPath.path)\"")
        return try self.decoder.readNumeric(T.self)
    }
}
