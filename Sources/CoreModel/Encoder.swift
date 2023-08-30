//
//  Encoder.swift
//  
//
//  Created by Alsey Coleman Miller on 8/18/23.
//

import Foundation

extension Entity where Self: Encodable {
        
    public func encode() throws -> ModelData {
        try encode(log: nil)
    }
    
    internal func encode(
        userInfo: [CodingUserInfoKey : Any] = [:],
        log: ((String) -> ())?
    ) throws -> ModelData {
        let entity = EntityDescription(entity: Self.self)
        let id = ObjectID(rawValue: self.id.description)
        let encoder = ModelDataEncoder(
            entity: entity,
            id: id,
            userInfo: userInfo,
            log: log
        )
        log?("Will encode \(Self.entityName) \(self.id)")
        try self.encode(to: encoder)
        return encoder.data
    }
}

internal final class ModelDataEncoder: Encoder {
    
    fileprivate(set) var codingPath: [CodingKey]
    
    let userInfo: [CodingUserInfoKey : Any]
        
    fileprivate(set) var data: ModelData
    
    fileprivate let log: ((String) -> ())?
    
    let attributes: [PropertyKey: Attribute]
    
    let relationships: [PropertyKey: Relationship]
    
    init(
        entity: EntityDescription,
        id: ObjectID,
        codingPath: [CodingKey] = [],
        userInfo: [CodingUserInfoKey : Any] = [:],
        log: ((String) -> ())? = nil
    ) {
        self.codingPath = codingPath
        self.userInfo = userInfo
        self.log = log
        self.data = ModelData(entity: entity.id, id: id)
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
    
    func container<Key>(keyedBy type: Key.Type) -> Swift.KeyedEncodingContainer<Key> where Key : CodingKey {
        log?("Requested container keyed by \(type.sanitizedName) for path \"\(codingPath.path)\"")
        let container = ModelKeyedEncodingContainer<Key>(referencing: self)
        return Swift.KeyedEncodingContainer<Key>(container)
    }
    
    func unkeyedContainer() -> Swift.UnkeyedEncodingContainer {
        log?("Requested unkeyed container for path \"\(codingPath.path)\"")
        return ModelUnkeyedEncodingContainer(referencing: self)
    }
    
    func singleValueContainer() -> Swift.SingleValueEncodingContainer {
        log?("Requested single value container for path \"\(codingPath.path)\"")
        assert(self.codingPath.last != nil)
        return ModelSingleValueEncodingContainer(referencing: self)
    }
}

internal extension ModelDataEncoder {
    
    func setAttribute(_ value: AttributeValue, forKey key: PropertyKey) throws {
        log?("Will set \(value) for attribute \"\(key)\"")
        guard relationships.keys.contains(key) == false else {
            assertionFailure("Trying to set \(value) for relationship \(key)")
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot set attribute value \(value) for relationship \(key)."))
        }
        guard attributes.keys.contains(key) else {
            // TODO: Determine if blacklisted key (e.g. _id)
            //throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: codingPath, debugDescription: "No attribute found for \"\(key)\""))
            return
        }
        data.attributes[key] = value
    }
    
    func setRelationship(_ value: RelationshipValue, forKey key: PropertyKey) throws {
        log?("Will set \(value) for relationship \"\(key)\"")
        guard relationships.keys.contains(key) else {
            //throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: codingPath, debugDescription: "No relationship found for \"\(key)\""))
            return
        }
        data.relationships[key] = value
    }
    
    func setNil(for key: PropertyKey) throws {
        log?("Will set nil for \"\(key)\"")
        if attributes.keys.contains(key) {
            data.attributes[key] = .null
        } else if relationships.keys.contains(key) {
            data.relationships[key] = .null
        } else {
            return
            //throw EncodingError.invalidValue(Optional<Any>.self, EncodingError.Context(codingPath: codingPath, debugDescription: "No property found for \"\(key)\""))
        }
    }
    
    func setEncodable <T: Encodable> (_ value: T, forKey key: PropertyKey) throws {
        
        if attributes.keys.contains(key), let encodable = value as? AttributeEncodable {
            try setAttribute(encodable.attributeValue, forKey: key)
        } else if relationships.keys.contains(key), let id = value as? ObjectIDConvertible {
            try setRelationship(.toOne(ObjectID(id)), forKey: key)
        } else {
            // encode using Encodable, container should write directly.
            try value.encode(to: self)
        }
    }
    
    func setString(_ string: String, forKey key: PropertyKey) throws {
        log?("Will set \"\(string)\" for \"\(key)\"")
        if attributes.keys.contains(key) {
            data.attributes[key] = .string(string)
        } else if relationships.keys.contains(key) {
            data.relationships[key] = .toOne(ObjectID(rawValue: string))
        } else {
            return
            //throw EncodingError.invalidValue(Optional<Any>.self, EncodingError.Context(codingPath: codingPath, debugDescription: "No property found for \"\(key)\""))
        }
    }
}

// MARK: - KeyedEncodingContainer

internal struct ModelKeyedEncodingContainer<K : CodingKey> : KeyedEncodingContainerProtocol {
        
    public typealias Key = K
    
    // MARK: Properties
    
    /// A reference to the encoder we're writing to.
    let encoder: ModelDataEncoder
    
    /// The path of coding keys taken to get to this point in encoding.
    let codingPath: [CodingKey]
    
    // MARK: Initialization
    
    init(referencing encoder: ModelDataEncoder) {
        self.encoder = encoder
        self.codingPath = encoder.codingPath
    }
    
    // MARK: Methods
    
    func encodeNil(forKey key: Key) throws {
        // set coding path
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        // set value
        try encoder.setNil(for: PropertyKey(key))
    }
    
    func encode(_ value: String, forKey key: Self.Key) throws {
        // Determine if attribute or relationship
        // set coding path
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        // set value
        try encoder.setString(value, forKey: PropertyKey(key))
    }
    
    func encode(_ value: Bool, forKey key: Key) throws {
        try writeAttribute(value, forKey: key)
    }
    
    func encode(_ value: Double, forKey key: Self.Key) throws {
        try writeAttribute(value, forKey: key)
    }
    
    func encode(_ value: Float, forKey key: Self.Key) throws {
        try writeAttribute(value, forKey: key)
    }
    
    func encode(_ value: Int, forKey key: Self.Key) throws {
        try writeAttribute(value, forKey: key)
    }
    
    func encode(_ value: Int8, forKey key: Self.Key) throws {
        try writeAttribute(value, forKey: key)
    }
    
    func encode(_ value: Int16, forKey key: Self.Key) throws {
        try writeAttribute(value, forKey: key)
    }
    
    func encode(_ value: Int32, forKey key: Self.Key) throws {
        try writeAttribute(value, forKey: key)
    }
    
    func encode(_ value: Int64, forKey key: Self.Key) throws {
        try writeAttribute(value, forKey: key)
    }
    
    func encode(_ value: UInt, forKey key: Self.Key) throws {
        try writeAttribute(value, forKey: key)
    }

    func encode(_ value: UInt8, forKey key: Self.Key) throws {
        try writeAttribute(value, forKey: key)
    }
    
    func encode(_ value: UInt16, forKey key: Self.Key) throws {
        try writeAttribute(value, forKey: key)
    }
    
    func encode(_ value: UInt32, forKey key: Self.Key) throws {
        try writeAttribute(value, forKey: key)
    }
    
    func encode(_ value: UInt64, forKey key: Self.Key) throws {
        try writeAttribute(value, forKey: key)
    }
    
    func encode<T>(_ value: T, forKey key: Self.Key) throws where T : Encodable {
        
        // set coding key context
        encoder.codingPath.append(key)
        defer { encoder.codingPath.removeLast() }
        
        // set value
        try encoder.setEncodable(value, forKey: PropertyKey(key))
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError()
    }
    
    func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        fatalError()
    }
    
    func superEncoder() -> Encoder {
        fatalError()
    }
    
    func superEncoder(forKey key: K) -> Encoder {
        fatalError()
    }
    
    // MARK: Private Methods
    
    private func writeAttribute<T: AttributeEncodable>(_ value: T, forKey key: Key) throws {
        
        // set coding key context
        encoder.codingPath.append(key)
        defer { encoder.codingPath.removeLast() }
        
        // set value
        try encoder.setAttribute(value.attributeValue, forKey: PropertyKey(key))
    }
}

// MARK: - SingleValueEncodingContainer

internal struct ModelSingleValueEncodingContainer: SingleValueEncodingContainer {
    
    // MARK: Properties
    
    /// A reference to the encoder we're writing to.
    let encoder: ModelDataEncoder
    
    /// The path of coding keys taken to get to this point in encoding.
    let codingPath: [CodingKey]
    
    // MARK: Initialization
    
    init(referencing encoder: ModelDataEncoder) {
        self.encoder = encoder
        self.codingPath = encoder.codingPath
    }
    
    // MARK: - Methods
    
    func encodeNil() throws {
        let key = try propertyKey()
        try encoder.setNil(for: key)
    }
    
    func encode(_ value: String) throws {
        let key = try propertyKey()
        try encoder.setString(value, forKey: key)
    }
    
    func encode(_ value: Bool) throws {
        try writeAttribute(value)
    }
    
    func encode(_ value: Double) throws {
        try writeAttribute(value)
    }
    
    func encode(_ value: Float) throws {
        try writeAttribute(value)
    }
    
    func encode(_ value: Int) throws {
        try writeAttribute(value)
    }
    
    func encode(_ value: Int8) throws {
        try writeAttribute(value)
    }
    
    func encode(_ value: Int16) throws {
        try writeAttribute(value)
    }
    
    func encode(_ value: Int32) throws {
        try writeAttribute(value)
    }
    
    func encode(_ value: Int64) throws {
        try writeAttribute(value)
    }
    
    func encode(_ value: UInt) throws {
        try writeAttribute(value)
    }
    
    func encode(_ value: UInt8) throws{
        try writeAttribute(value)
    }
    
    func encode(_ value: UInt16) throws{
        try writeAttribute(value)
    }
    
    func encode(_ value: UInt32) throws{
        try writeAttribute(value)
    }
    
    func encode(_ value: UInt64) throws {
        try writeAttribute(value)
    }
    
    func encode <T: Encodable> (_ value: T) throws {
        let key = try self.propertyKey()
        try encoder.setEncodable(value, forKey: key)
    }
    
    // MARK: Private Methods
    
    private func propertyKey() throws -> PropertyKey {
        guard let key = codingPath.first else {
            throw EncodingError.invalidValue(Any.self, EncodingError.Context(codingPath: codingPath, debugDescription: "Invalid coding path"))
        }
        return PropertyKey(key)
    }
    
    private func writeAttribute<T: AttributeEncodable>(_ value: T) throws {
        let key = try self.propertyKey()
        try encoder.setAttribute(value.attributeValue, forKey: key)
    }
}


// MARK: - UnkeyedEncodingContainer

internal final class ModelUnkeyedEncodingContainer: UnkeyedEncodingContainer {
        
    // MARK: Properties
    
    /// A reference to the encoder we're writing to.
    let encoder: ModelDataEncoder
    
    /// The path of coding keys taken to get to this point in encoding.
    let codingPath: [CodingKey]
    
    private var objectIDs = [ObjectID]()
        
    // MARK: Initialization
    
    init(referencing encoder: ModelDataEncoder) {
        self.encoder = encoder
        self.codingPath = encoder.codingPath
    }
    
    deinit {
        writeArray()
    }
    
    // MARK: - Methods
    
    var count: Int {
        objectIDs.count
    }
    
    func encodeNil() throws {
        throw EncodingError.invalidValue(type(of: Optional<Any>.self), EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode to-many relationship of \(Optional<Any>.self)"))
    }
    
    func encode(_ value: String) throws {
        try encodeRelationship(value)
    }
    
    func encode(_ value: Bool) throws {
        throw EncodingError.invalidValue(type(of: value), EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode to-many relationship of \(type(of: value))"))
    }
    
    func encode(_ value: Double) throws {
        throw EncodingError.invalidValue(type(of: value), EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode to-many relationship of \(type(of: value))"))
    }
    
    func encode(_ value: Float) throws {
        throw EncodingError.invalidValue(type(of: value), EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode to-many relationship of \(type(of: value))"))
    }
    
    func encode(_ value: Int) throws {
        throw EncodingError.invalidValue(type(of: value), EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode to-many relationship of \(type(of: value))"))
    }
    
    func encode(_ value: Int8) throws {
        throw EncodingError.invalidValue(type(of: value), EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode to-many relationship of \(type(of: value))"))
    }
    
    func encode(_ value: Int16) throws {
        throw EncodingError.invalidValue(type(of: value), EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode to-many relationship of \(type(of: value))"))
    }
    
    func encode(_ value: Int32) throws {
        throw EncodingError.invalidValue(type(of: value), EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode to-many relationship of \(type(of: value))"))
    }
    
    func encode(_ value: Int64) throws {
        throw EncodingError.invalidValue(type(of: value), EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode to-many relationship of \(type(of: value))"))
    }
    
    func encode(_ value: UInt) throws {
        throw EncodingError.invalidValue(type(of: value), EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode to-many relationship of \(type(of: value))"))
    }
    
    func encode(_ value: UInt8) throws {
        throw EncodingError.invalidValue(type(of: value), EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode to-many relationship of \(type(of: value))"))
    }
    
    func encode(_ value: UInt16) throws {
        throw EncodingError.invalidValue(type(of: value), EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode to-many relationship of \(type(of: value))"))
    }
    
    func encode(_ value: UInt32) throws {
        throw EncodingError.invalidValue(type(of: value), EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode to-many relationship of \(type(of: value))"))
    }
    
    func encode(_ value: UInt64) throws {
        throw EncodingError.invalidValue(type(of: value), EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode to-many relationship of \(type(of: value))"))
    }
    
    func encode <T: Encodable> (_ value: T) throws {
        guard let stringConvertible = value as? CustomStringConvertible else {
            throw EncodingError.invalidValue(type(of: value), EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode to-many relationship of \(type(of: value))"))
        }
        let string = stringConvertible.description
        try encodeRelationship(string)
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError()
    }
    
    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError()
    }
    
    func superEncoder() -> Encoder {
        encoder
    }
    
    // MARK: Private Methods
    
    private func propertyKey() throws -> PropertyKey {
        guard let key = codingPath.first else {
            throw EncodingError.invalidValue(Any.self, EncodingError.Context(codingPath: codingPath, debugDescription: "Invalid coding path"))
        }
        return PropertyKey(key)
    }
    
    private func encodeRelationship(_ string: String) throws {
        objectIDs.append(ObjectID(rawValue: string))
    }
    
    private func writeArray() {
        // set key to be written
        guard let codingKey = codingPath.first else {
            //throw EncodingError.invalidValue(Any.self, EncodingError.Context(codingPath: codingPath, debugDescription: "Invalid coding path"))
            return
        }
        let key = PropertyKey(codingKey)
        // write final value
        let value = RelationshipValue.toMany(objectIDs)
        encoder.log?("Will set \(value) for relationship \"\(key)\"")
        encoder.data.relationships[key] = value
    }
}
