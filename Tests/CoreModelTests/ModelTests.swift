//
//  ModelTests.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/17/25.
//

import Foundation
import XCTest
@testable import CoreModel
#if canImport(CoreData)
@testable import CoreDataModel
#endif

final class ModelTests: XCTestCase {

    func testModel() throws {
        let model = Model(entities: Person.self, Event.self)
        XCTAssertEqual(model.entities.count, 2)
        // subscript
        XCTAssertNotNil(model[Person.entityName])
        XCTAssertNotNil(model["Event"])
        XCTAssertNil(model["Missing"])
        // codable round trip
        let data = try JSONEncoder().encode(model)
        let decoded = try JSONDecoder().decode(Model.self, from: data)
        XCTAssertEqual(decoded, model)
    }

    func testEntityName() throws {
        let name: EntityName = "Person"
        XCTAssertEqual(name.rawValue, "Person")
        XCTAssertEqual(name.description, "Person")
        XCTAssertEqual(name.debugDescription, "Person")
        let data = try JSONEncoder().encode(name)
        XCTAssertEqual(try JSONDecoder().decode(EntityName.self, from: data), name)
    }

    func testPropertyKey() throws {
        let key: PropertyKey = "name"
        XCTAssertEqual(key.rawValue, "name")
        XCTAssertEqual(key.description, "name")
        XCTAssertEqual(key.debugDescription, "name")
        XCTAssertEqual(PropertyKey(Person.CodingKeys.name), key)
        let data = try JSONEncoder().encode(key)
        XCTAssertEqual(try JSONDecoder().decode(PropertyKey.self, from: data), key)
    }

    func testEntityDefaultImplementations() {
        // entity with no attributes or relationships uses protocol defaults
        struct Empty: Entity {
            typealias ID = UUID
            let id: UUID
            enum CodingKeys: CodingKey {
                case id
            }
            init(from model: ModelData) throws {
                self.id = UUID(objectID: model.id)!
            }
            init(id: UUID) {
                self.id = id
            }
            func encode() throws -> ModelData {
                ModelData(entity: Self.entityName, id: ObjectID(id))
            }
        }
        XCTAssertEqual(Empty.entityName.rawValue, "Empty")
        XCTAssertEqual(Empty.attributes, [:])
        XCTAssertEqual(Empty.relationships, [:])
        let description = EntityDescription(entity: Empty.self)
        XCTAssertEqual(description.id, Empty.entityName)
        XCTAssertEqual(description.attributes, [])
        XCTAssertEqual(description.relationships, [])
    }

    func testModelDataCodable() throws {
        var data = ModelData(entity: "Person", id: "1")
        data.encode("Alice", forKey: PredicateCodingTests.Key.name)
        data.encodeRelationship([UUID()], forKey: PredicateCodingTests.Key.age)
        let encoded = try JSONEncoder().encode(data)
        let decoded = try JSONDecoder().decode(ModelData.self, from: encoded)
        XCTAssertEqual(decoded, data)
    }

    #if canImport(CoreData)
    func testNSNumberConversion() {
        XCTAssertEqual(NSNumber(value: .bool(true)), NSNumber(value: true))
        XCTAssertEqual(NSNumber(value: .int16(16)), NSNumber(value: Int16(16)))
        XCTAssertEqual(NSNumber(value: .int32(32)), NSNumber(value: Int32(32)))
        XCTAssertEqual(NSNumber(value: .int64(64)), NSNumber(value: Int64(64)))
        XCTAssertEqual(NSNumber(value: .float(1.5)), NSNumber(value: Float(1.5)))
        XCTAssertEqual(NSNumber(value: .double(2.5)), NSNumber(value: Double(2.5)))
        XCTAssertNil(NSNumber(value: .string("x")))
        XCTAssertNil(NSNumber(value: .null))
    }
    #endif
}
