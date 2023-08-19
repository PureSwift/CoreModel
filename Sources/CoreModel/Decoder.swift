//
//  Decoder.swift
//  
//
//  Created by Alsey Coleman Miller on 8/18/23.
//

import Foundation

// MARK: - Default Codable Implementation

extension Entity where Self: Decodable {
    
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
        log?("Will decode \(model.entity) \(model.id)")
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
        self.identifierKey = identifierKey
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
        guard attributes.keys.contains(property) else {
            throw DecodingError.typeMismatch(T.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Unknown attribute for \"\(key.stringValue)\""))
        }
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
        let property = PropertyKey(key)
        // override for native types and id
        if key.stringValue == identifierKey {
            log?("Will decode \(type) at path \"\(codingPath.path)\"")
            guard let convertible = type as? ObjectIDConvertible.Type else {
                throw DecodingError.typeMismatch(ObjectIDConvertible.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode identifer from \(type). Types used as identifiers must conform to \(String(describing: ObjectIDConvertible.self))"))
            }
            let id = self.data.id
            guard let value = convertible.init(objectID: id) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode \(type) from identifier \(id)"))
            }
            return value as! T
        } else if let relationship = relationships[property] {
            log?("Will decode \(type) at path \"\(codingPath.path)\"")
            guard let relationshipValue = self.data.relationships[property] else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Missing relationship value for \(key.stringValue)"))
            }
            switch (relationship.type, relationshipValue) {
            case (_, .null):
                //assertionFailure()
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected \(type) value for \(key.stringValue)"))
            case (.toMany, .toMany):
                return try T.init(from: self)
            case (.toOne, .toOne(let objectID)):
                guard let convertible = type as? ObjectIDConvertible.Type else {
                    throw DecodingError.typeMismatch(ObjectIDConvertible.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode identifer from \(type). Types used as identifiers must conform to \(String(describing: ObjectIDConvertible.self))"))
                }
                guard let value = convertible.init(objectID: objectID) else {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode \(type) from identifier \(objectID)"))
                }
                return value as! T
            default:
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode relationship from \(type)."))
            }
        } else if let decodableType = type as? AttributeDecodable.Type {
            return try decodeAttribute(decodableType, forKey: key) as! T
        } else {
            // decode using Decodable, container should read directly.
            log?("Will decode \(type) at path \"\(codingPath.path)\"")
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
        return try self.decoder.decodeString(forKey: key)
    }
    
    func decode <T: Decodable> (_ type: T.Type, forKey key: Key) throws -> T {
        
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
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

// MARK: - UnkeyedDecodingContainer

internal struct ModelDataUnkeyedDecodingContainer: UnkeyedDecodingContainer {
        
    // MARK: Properties
    
    /// A reference to the encoder we're reading from.
    let decoder: ModelDataDecoder
    
    /// The path of coding keys taken to get to this point in decoding.
    let codingPath: [CodingKey]
    
    let objectIDs: [ObjectID]
    
    private(set) var currentIndex: Int = 0
    
    // MARK: Initialization
    
    /// Initializes `self` by referencing the given decoder and container.
    init(referencing decoder: ModelDataDecoder) throws {
        
        self.decoder = decoder
        self.codingPath = decoder.codingPath
        // get to-many relationship
        guard let key = codingPath.first else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Cannot decode to-many relationship from root data."))
        }
        guard let relationship = decoder.data.relationships[PropertyKey(key)] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No relationship value for \(key.stringValue)"))
        }
        switch relationship {
        case .null:
            self.objectIDs = []
        case let .toMany(objectIDs):
            self.objectIDs = objectIDs
        case .toOne:
            throw DecodingError.typeMismatch([String].self, DecodingError.Context(codingPath: codingPath, debugDescription: "Invalid relationship value \(relationship)"))
        }
    }
    
    // MARK: UnkeyedDecodingContainer
    
    var count: Int? {
        objectIDs.count
    }
    
    var isAtEnd: Bool {
        currentIndex >= objectIDs.count
    }
    
    func decodeNil() throws -> Bool {
        throw DecodingError.typeMismatch(Optional<Any>.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode to-many relationship of \(Optional<Any>.self)"))
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode to-many relationship of \(type)"))
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode to-many relationship of \(type)"))
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode to-many relationship of \(type)"))
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode to-many relationship of \(type)"))
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode to-many relationship of \(type)"))
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode to-many relationship of \(type)"))
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode to-many relationship of \(type)"))
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode to-many relationship of \(type)"))
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode to-many relationship of \(type)"))
    }


    func decode(_ type: UInt8.Type) throws -> UInt8 {
        throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode to-many relationship of \(type)"))
    }


    func decode(_ type: UInt16.Type) throws -> UInt16 {
        throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode to-many relationship of \(type)"))
    }


    func decode(_ type: UInt32.Type) throws -> UInt32 {
        throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode to-many relationship of \(type)"))
    }


    func decode(_ type: UInt64.Type) throws -> UInt64 {
        throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode to-many relationship of \(type)"))
    }
        
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError()
    }
    
    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        fatalError()
    }
    
    func superDecoder() throws -> Decoder {
        decoder
    }
    
    mutating func decode(_ type: String.Type) throws -> String {
        let indexKey = IndexCodingKey(rawValue: currentIndex)
        self.decoder.codingPath.append(indexKey)
        defer { self.decoder.codingPath.removeLast() }
        return try decodeRelationship(type)
    }
    
    mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        let indexKey = IndexCodingKey(rawValue: currentIndex)
        self.decoder.codingPath.append(indexKey)
        defer { self.decoder.codingPath.removeLast() }
        let string = try decodeRelationship(type)
        let id = ObjectID(rawValue: string)
        guard let convertible = type as? ObjectIDConvertible.Type else {
            throw DecodingError.typeMismatch(ObjectIDConvertible.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Cannot decode identifer from \(type). Types used as identifiers must conform to \(String(describing: ObjectID.self))"))
        }
        guard let value = convertible.init(objectID: id) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Cannot decode \(type) from identifier \(id)"))
        }
        return value as! T
    }
    
    // MARK: Private Methods
    
    private mutating func decodeRelationship<T>(_ type: T.Type) throws -> String {
        guard objectIDs.count > currentIndex else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "End of to many relationship"))
        }
        let objectID = objectIDs[currentIndex]
        // increment index
        currentIndex += 1
        // return value
        return objectID.rawValue
    }
}

internal struct IndexCodingKey: CodingKey, RawRepresentable, Equatable, Hashable {
    
    let rawValue: Int
    
    init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    var stringValue: String {
        rawValue.description
    }
    
    init?(stringValue: String) {
        guard let rawValue = Int(stringValue) else {
            return nil
        }
        self.init(rawValue: rawValue)
    }
    
    var intValue: Int? {
        rawValue
    }
    
    init?(intValue: Int) {
        self.init(rawValue: intValue)
    }
    
    
    
}
