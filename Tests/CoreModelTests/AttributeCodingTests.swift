//
//  AttributeCodingTests.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/17/25.
//

import Foundation
import XCTest
@testable import CoreModel

final class AttributeCodingTests: XCTestCase {

    enum Key: CodingKey {
        case value
        case other
    }

    enum Color: String, AttributeEncodable, AttributeDecodable {
        case red
        case blue
    }

    // MARK: - AttributeEncodable

    func testEncodeAttributeValues() {
        XCTAssertEqual(true.attributeValue, .bool(true))
        XCTAssertEqual("test".attributeValue, .string("test"))
        XCTAssertEqual(Int(1).attributeValue, .int64(1))
        XCTAssertEqual(Int8(2).attributeValue, .int16(2))
        XCTAssertEqual(Int16(3).attributeValue, .int16(3))
        XCTAssertEqual(Int32(4).attributeValue, .int32(4))
        XCTAssertEqual(Int64(5).attributeValue, .int64(5))
        XCTAssertEqual(UInt(6).attributeValue, .int64(6))
        XCTAssertEqual(UInt8(7).attributeValue, .int16(7))
        XCTAssertEqual(UInt16(8).attributeValue, .int32(8))
        XCTAssertEqual(UInt32(9).attributeValue, .int64(9))
        XCTAssertEqual(UInt64(10).attributeValue, .int64(10))
        XCTAssertEqual(Float(1.5).attributeValue, .float(1.5))
        XCTAssertEqual(Double(2.5).attributeValue, .double(2.5))
        let date = Date(timeIntervalSince1970: 100)
        XCTAssertEqual(date.attributeValue, .date(date))
        let data = Data([0x01, 0x02])
        XCTAssertEqual(data.attributeValue, .data(data))
        let uuid = UUID()
        XCTAssertEqual(uuid.attributeValue, .uuid(uuid))
        let url = URL(string: "https://example.com")!
        XCTAssertEqual(url.attributeValue, .url(url))
        let decimal = Decimal(string: "3.14")!
        XCTAssertEqual(decimal.attributeValue, .decimal(decimal))
        // RawRepresentable
        XCTAssertEqual(Color.red.attributeValue, .string("red"))
        // Optional
        XCTAssertEqual(Optional<String>.none.attributeValue, .null)
        XCTAssertEqual(Optional<String>.some("test").attributeValue, .string("test"))
    }

    // MARK: - AttributeDecodable

    func testDecodeAttributeValues() {
        XCTAssertEqual(Bool(attributeValue: .bool(true)), true)
        XCTAssertNil(Bool(attributeValue: .string("true")))
        XCTAssertEqual(String(attributeValue: .string("test")), "test")
        XCTAssertNil(String(attributeValue: .bool(false)))
        let uuid = UUID()
        XCTAssertEqual(UUID(attributeValue: .uuid(uuid)), uuid)
        XCTAssertNil(UUID(attributeValue: .null))
        let url = URL(string: "https://example.com")!
        XCTAssertEqual(URL(attributeValue: .url(url)), url)
        XCTAssertNil(URL(attributeValue: .null))
        let date = Date(timeIntervalSince1970: 100)
        XCTAssertEqual(Date(attributeValue: .date(date)), date)
        XCTAssertNil(Date(attributeValue: .null))
        let data = Data([0x01])
        XCTAssertEqual(Data(attributeValue: .data(data)), data)
        XCTAssertNil(Data(attributeValue: .null))
        let decimal = Decimal(string: "3.14")!
        XCTAssertEqual(Decimal(attributeValue: .decimal(decimal)), decimal)
        XCTAssertNil(Decimal(attributeValue: .double(3.14)))
        XCTAssertEqual(Float(attributeValue: .float(1.5)), 1.5)
        XCTAssertNil(Float(attributeValue: .double(1.5)))
        XCTAssertEqual(Double(attributeValue: .double(2.5)), 2.5)
        XCTAssertNil(Double(attributeValue: .float(2.5)))
        // RawRepresentable
        XCTAssertEqual(Color(attributeValue: .string("red")), .red)
        XCTAssertNil(Color(attributeValue: .string("green")))
        XCTAssertNil(Color(attributeValue: .bool(true)))
        // Optional
        XCTAssertEqual(Optional<String>(attributeValue: .null), .some(.none))
        XCTAssertEqual(Optional<String>(attributeValue: .string("x")), "x")
        XCTAssertNil(Optional<String>(attributeValue: .bool(true)))
    }

    func testDecodeIntegerValues() {
        // every integer type decodes from all three stored widths
        func verify<T>(_ type: T.Type) where T: AttributeDecodable & FixedWidthInteger {
            XCTAssertEqual(T(attributeValue: .int16(16)), 16)
            XCTAssertEqual(T(attributeValue: .int32(32)), 32)
            XCTAssertEqual(T(attributeValue: .int64(64)), 64)
            XCTAssertNil(T(attributeValue: .null))
            XCTAssertNil(T(attributeValue: .string("1")))
            XCTAssertNil(T(attributeValue: .bool(true)))
            XCTAssertNil(T(attributeValue: .float(1)))
            XCTAssertNil(T(attributeValue: .double(1)))
            XCTAssertNil(T(attributeValue: .date(Date())))
            XCTAssertNil(T(attributeValue: .uuid(UUID())))
            XCTAssertNil(T(attributeValue: .url(URL(string: "https://example.com")!)))
            XCTAssertNil(T(attributeValue: .data(Data())))
            XCTAssertNil(T(attributeValue: .decimal(1)))
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

    func testModelDataDecode() throws {
        var model = ModelData(entity: "Test", id: "1")
        model.encode("value", forKey: Key.value)
        XCTAssertEqual(try model.decode(String.self, forKey: Key.value), "value")
        // key not found
        XCTAssertThrowsError(try model.decode(String.self, forKey: Key.other)) { error in
            guard case DecodingError.keyNotFound = error else {
                return XCTFail("Expected keyNotFound, got \(error)")
            }
        }
        // type mismatch
        XCTAssertThrowsError(try model.decode(Bool.self, forKey: Key.value)) { error in
            guard case DecodingError.typeMismatch = error else {
                return XCTFail("Expected typeMismatch, got \(error)")
            }
        }
    }

    // MARK: - ModelData relationship decoding

    func testDecodeToOneRelationship() throws {
        let uuid = UUID()
        var model = ModelData(entity: "Test", id: "1")
        model.encodeRelationship(uuid, forKey: Key.value)
        XCTAssertEqual(try model.decodeRelationship(UUID.self, forKey: Key.value), uuid)
        // key not found
        XCTAssertThrowsError(try model.decodeRelationship(UUID.self, forKey: Key.other))
        // null throws for non-optional
        model.relationships[PropertyKey(Key.value)] = .null
        XCTAssertThrowsError(try model.decodeRelationship(UUID.self, forKey: Key.value))
        // to-many mismatch
        model.relationships[PropertyKey(Key.value)] = .toMany([ObjectID(uuid)])
        XCTAssertThrowsError(try model.decodeRelationship(UUID.self, forKey: Key.value))
        // invalid identifier
        model.relationships[PropertyKey(Key.value)] = .toOne("not-a-uuid")
        XCTAssertThrowsError(try model.decodeRelationship(UUID.self, forKey: Key.value))
    }

    func testDecodeOptionalRelationship() throws {
        let uuid = UUID()
        var model = ModelData(entity: "Test", id: "1")
        // missing key decodes as nil
        XCTAssertNil(try model.decodeRelationship(UUID?.self, forKey: Key.value))
        // null decodes as nil
        model.encodeRelationship(UUID?.none, forKey: Key.value)
        XCTAssertNil(try model.decodeRelationship(UUID?.self, forKey: Key.value))
        // value decodes
        model.encodeRelationship(UUID?.some(uuid), forKey: Key.value)
        XCTAssertEqual(try model.decodeRelationship(UUID?.self, forKey: Key.value), uuid)
        // to-many mismatch
        model.relationships[PropertyKey(Key.value)] = .toMany([ObjectID(uuid)])
        XCTAssertThrowsError(try model.decodeRelationship(UUID?.self, forKey: Key.value))
        // invalid identifier
        model.relationships[PropertyKey(Key.value)] = .toOne("not-a-uuid")
        XCTAssertThrowsError(try model.decodeRelationship(UUID?.self, forKey: Key.value))
    }

    func testDecodeToManyRelationship() throws {
        let ids = [UUID(), UUID()]
        var model = ModelData(entity: "Test", id: "1")
        // missing key throws
        XCTAssertThrowsError(try model.decodeRelationship([UUID].self, forKey: Key.value))
        // values decode
        model.encodeRelationship(ids, forKey: Key.value)
        XCTAssertEqual(try model.decodeRelationship([UUID].self, forKey: Key.value), ids)
        // null decodes as empty
        model.relationships[PropertyKey(Key.value)] = .null
        XCTAssertEqual(try model.decodeRelationship([UUID].self, forKey: Key.value), [])
        // to-one mismatch
        model.relationships[PropertyKey(Key.value)] = .toOne(ObjectID(ids[0]))
        XCTAssertThrowsError(try model.decodeRelationship([UUID].self, forKey: Key.value))
        // invalid identifier
        model.relationships[PropertyKey(Key.value)] = .toMany(["not-a-uuid"])
        XCTAssertThrowsError(try model.decodeRelationship([UUID].self, forKey: Key.value))
    }

    // MARK: - ObjectID

    func testObjectID() {
        let id: ObjectID = "test-id"
        XCTAssertEqual(id.rawValue, "test-id")
        XCTAssertEqual(id.description, "test-id")
        XCTAssertEqual(id.debugDescription, "test-id")
        let uuid = UUID()
        XCTAssertEqual(ObjectID(uuid).rawValue, uuid.uuidString)
        XCTAssertEqual(UUID(objectID: ObjectID(uuid)), uuid)
        XCTAssertNil(UUID(objectID: "invalid"))
        XCTAssertEqual(String(objectID: "value"), "value")
        // RawRepresentable conversion
        XCTAssertEqual(Color(objectID: "red"), Color.red)
        XCTAssertNil(Color(objectID: "green"))
        // Optional conversion
        XCTAssertEqual(UUID?(objectID: ObjectID(uuid)), uuid)
        XCTAssertNil(UUID?(objectID: "invalid"))
        // Optional description
        XCTAssertEqual(UUID?.none.description, "")
        XCTAssertEqual(UUID?.some(uuid).description, uuid.uuidString)
    }
}

extension AttributeCodingTests.Color: ObjectIDConvertible {

    var description: String { rawValue }
}
