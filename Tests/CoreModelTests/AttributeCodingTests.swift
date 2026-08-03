//
//  AttributeCodingTests.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/17/25.
//

import Foundation
import Testing
@testable import CoreModel

@Suite struct AttributeCodingTests {

    enum Key: CodingKey {
        case value
        case other
    }

    enum Color: String, AttributeEncodable, AttributeDecodable {
        case red
        case blue
    }

    // MARK: - AttributeEncodable

    @Test func encodeAttributeValues() {
        #expect(true.attributeValue == .bool(true))
        #expect("test".attributeValue == .string("test"))
        #expect(Int(1).attributeValue == .int64(1))
        #expect(Int8(2).attributeValue == .int16(2))
        #expect(Int16(3).attributeValue == .int16(3))
        #expect(Int32(4).attributeValue == .int32(4))
        #expect(Int64(5).attributeValue == .int64(5))
        #expect(UInt(6).attributeValue == .int64(6))
        #expect(UInt8(7).attributeValue == .int16(7))
        #expect(UInt16(8).attributeValue == .int32(8))
        #expect(UInt32(9).attributeValue == .int64(9))
        #expect(UInt64(10).attributeValue == .int64(10))
        #expect(Float(1.5).attributeValue == .float(1.5))
        #expect(Double(2.5).attributeValue == .double(2.5))
        let date = Date(timeIntervalSince1970: 100)
        #expect(date.attributeValue == .date(date))
        let data = Data([0x01, 0x02])
        #expect(data.attributeValue == .data(data))
        let uuid = UUID()
        #expect(uuid.attributeValue == .uuid(uuid))
        let url = URL(string: "https://example.com")!
        #expect(url.attributeValue == .url(url))
        let decimal = Decimal(string: "3.14")!
        #expect(decimal.attributeValue == .decimal(decimal))
        // RawRepresentable
        #expect(Color.red.attributeValue == .string("red"))
        // Optional
        #expect(Optional<String>.none.attributeValue == .null)
        #expect(Optional<String>.some("test").attributeValue == .string("test"))
    }

    // MARK: - AttributeDecodable

    @Test func decodeAttributeValues() {
        #expect(Bool(attributeValue: .bool(true)) == true)
        #expect(Bool(attributeValue: .string("true")) == nil)
        #expect(String(attributeValue: .string("test")) == "test")
        #expect(String(attributeValue: .bool(false)) == nil)
        let uuid = UUID()
        #expect(UUID(attributeValue: .uuid(uuid)) == uuid)
        #expect(UUID(attributeValue: .null) == nil)
        let url = URL(string: "https://example.com")!
        #expect(URL(attributeValue: .url(url)) == url)
        #expect(URL(attributeValue: .null) == nil)
        let date = Date(timeIntervalSince1970: 100)
        #expect(Date(attributeValue: .date(date)) == date)
        #expect(Date(attributeValue: .null) == nil)
        let data = Data([0x01])
        #expect(Data(attributeValue: .data(data)) == data)
        #expect(Data(attributeValue: .null) == nil)
        let decimal = Decimal(string: "3.14")!
        #expect(Decimal(attributeValue: .decimal(decimal)) == decimal)
        #expect(Decimal(attributeValue: .double(3.14)) == nil)
        #expect(Float(attributeValue: .float(1.5)) == 1.5)
        #expect(Float(attributeValue: .double(1.5)) == nil)
        #expect(Double(attributeValue: .double(2.5)) == 2.5)
        #expect(Double(attributeValue: .float(2.5)) == nil)
        // RawRepresentable
        #expect(Color(attributeValue: .string("red")) == .red)
        #expect(Color(attributeValue: .string("green")) == nil)
        #expect(Color(attributeValue: .bool(true)) == nil)
        // Optional
        #expect(Optional<String>(attributeValue: .null) == .some(.none))
        #expect(Optional<String>(attributeValue: .string("x")) == "x")
        #expect(Optional<String>(attributeValue: .bool(true)) == nil)
    }

    @Test func decodeIntegerValues() {
        // every integer type decodes from all three stored widths
        func verify<T>(_ type: T.Type) where T: AttributeDecodable & FixedWidthInteger {
            #expect(T(attributeValue: .int16(16)) == 16)
            #expect(T(attributeValue: .int32(32)) == 32)
            #expect(T(attributeValue: .int64(64)) == 64)
            #expect(T(attributeValue: .null) == nil)
            #expect(T(attributeValue: .string("1")) == nil)
            #expect(T(attributeValue: .bool(true)) == nil)
            #expect(T(attributeValue: .float(1)) == nil)
            #expect(T(attributeValue: .double(1)) == nil)
            #expect(T(attributeValue: .date(Date())) == nil)
            #expect(T(attributeValue: .uuid(UUID())) == nil)
            #expect(T(attributeValue: .url(URL(string: "https://example.com")!)) == nil)
            #expect(T(attributeValue: .data(Data())) == nil)
            #expect(T(attributeValue: .decimal(1)) == nil)
        }
        verify(Int.self)
        verify(Int8.self)
        verify(Int16.self)
        verify(Int32.self)
        verify(Int64.self)
        verify(UInt.self)
        verify(UInt8.self)
        verify(UInt16.self)
        verify(UInt32.self)
        verify(UInt64.self)
    }

    // MARK: - ModelData attribute decoding

    @Test func modelDataDecode() throws {
        var model = ModelData(entity: "Test", id: "1")
        model.encode("value", forKey: Key.value)
        #expect(try model.decode(String.self, forKey: Key.value) == "value")
        // key not found
        do {
            _ = try model.decode(String.self, forKey: Key.other)
            Issue.record("Expected an error")
        } catch DecodingError.keyNotFound {
            // expected
        } catch {
            Issue.record("Expected keyNotFound, got \(error)")
        }
        // type mismatch
        do {
            _ = try model.decode(Bool.self, forKey: Key.value)
            Issue.record("Expected an error")
        } catch DecodingError.typeMismatch {
            // expected
        } catch {
            Issue.record("Expected typeMismatch, got \(error)")
        }
    }

    // MARK: - ModelData relationship decoding

    @Test func decodeToOneRelationship() throws {
        let uuid = UUID()
        var model = ModelData(entity: "Test", id: "1")
        model.encodeRelationship(uuid, forKey: Key.value)
        #expect(try model.decodeRelationship(UUID.self, forKey: Key.value) == uuid)
        // key not found
        #expect(throws: (any Error).self) { try model.decodeRelationship(UUID.self, forKey: Key.other) }
        // null throws for non-optional
        model.relationships[PropertyKey(Key.value)] = .null
        #expect(throws: (any Error).self) { try model.decodeRelationship(UUID.self, forKey: Key.value) }
        // to-many mismatch
        model.relationships[PropertyKey(Key.value)] = .toMany([ObjectID(uuid)])
        #expect(throws: (any Error).self) { try model.decodeRelationship(UUID.self, forKey: Key.value) }
        // invalid identifier
        model.relationships[PropertyKey(Key.value)] = .toOne("not-a-uuid")
        #expect(throws: (any Error).self) { try model.decodeRelationship(UUID.self, forKey: Key.value) }
    }

    @Test func decodeOptionalRelationship() throws {
        let uuid = UUID()
        var model = ModelData(entity: "Test", id: "1")
        // missing key decodes as nil
        #expect(try model.decodeRelationship(UUID?.self, forKey: Key.value) == nil)
        // null decodes as nil
        model.encodeRelationship(UUID?.none, forKey: Key.value)
        #expect(try model.decodeRelationship(UUID?.self, forKey: Key.value) == nil)
        // value decodes
        model.encodeRelationship(UUID?.some(uuid), forKey: Key.value)
        #expect(try model.decodeRelationship(UUID?.self, forKey: Key.value) == uuid)
        // to-many mismatch
        model.relationships[PropertyKey(Key.value)] = .toMany([ObjectID(uuid)])
        #expect(throws: (any Error).self) { try model.decodeRelationship(UUID?.self, forKey: Key.value) }
        // invalid identifier
        model.relationships[PropertyKey(Key.value)] = .toOne("not-a-uuid")
        #expect(throws: (any Error).self) { try model.decodeRelationship(UUID?.self, forKey: Key.value) }
    }

    @Test func decodeToManyRelationship() throws {
        let ids = [UUID(), UUID()]
        var model = ModelData(entity: "Test", id: "1")
        // missing key throws
        #expect(throws: (any Error).self) { try model.decodeRelationship([UUID].self, forKey: Key.value) }
        // values decode
        model.encodeRelationship(ids, forKey: Key.value)
        #expect(try model.decodeRelationship([UUID].self, forKey: Key.value) == ids)
        // null decodes as empty
        model.relationships[PropertyKey(Key.value)] = .null
        #expect(try model.decodeRelationship([UUID].self, forKey: Key.value) == [])
        // to-one mismatch
        model.relationships[PropertyKey(Key.value)] = .toOne(ObjectID(ids[0]))
        #expect(throws: (any Error).self) { try model.decodeRelationship([UUID].self, forKey: Key.value) }
        // invalid identifier
        model.relationships[PropertyKey(Key.value)] = .toMany(["not-a-uuid"])
        #expect(throws: (any Error).self) { try model.decodeRelationship([UUID].self, forKey: Key.value) }
    }

    // MARK: - ObjectID

    @Test func objectID() {
        let id: ObjectID = "test-id"
        #expect(id.rawValue == "test-id")
        #expect(id.description == "test-id")
        #expect(id.debugDescription == "test-id")
        let uuid = UUID()
        #expect(ObjectID(uuid).rawValue == uuid.uuidString)
        #expect(UUID(objectID: ObjectID(uuid)) == uuid)
        #expect(UUID(objectID: "invalid") == nil)
        #expect(String(objectID: "value") == "value")
        // RawRepresentable conversion
        #expect(Color(objectID: "red") == Color.red)
        #expect(Color(objectID: "green") == nil)
        // Optional conversion
        #expect(UUID?(objectID: ObjectID(uuid)) == uuid)
        #expect(UUID?(objectID: "invalid") == nil)
        // Optional description
        #expect(UUID?.none.description == "")
        #expect(UUID?.some(uuid).description == uuid.uuidString)
    }
}

extension AttributeCodingTests.Color: ObjectIDConvertible {

    var description: String { rawValue }
}
