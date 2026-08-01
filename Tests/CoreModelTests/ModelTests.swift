//
//  ModelTests.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/17/25.
//

import Foundation
import Testing
@testable import CoreModel
#if canImport(CoreData)
@testable import CoreDataModel
#endif

@Suite struct ModelTests {

    @Test func model() throws {
        let model = Model(entities: Person.self, Event.self)
        #expect(model.entities.count == 2)
        // subscript
        #expect(model[Person.entityName] != nil)
        #expect(model["Event"] != nil)
        #expect(model["Missing"] == nil)
        // codable round trip
        let data = try JSONEncoder().encode(model)
        let decoded = try JSONDecoder().decode(Model.self, from: data)
        #expect(decoded == model)
    }

    @Test func entityName() throws {
        let name: EntityName = "Person"
        #expect(name.rawValue == "Person")
        #expect(name.description == "Person")
        #expect(name.debugDescription == "Person")
        let data = try JSONEncoder().encode(name)
        #expect(try JSONDecoder().decode(EntityName.self, from: data) == name)
    }

    @Test func propertyKey() throws {
        let key: PropertyKey = "name"
        #expect(key.rawValue == "name")
        #expect(key.description == "name")
        #expect(key.debugDescription == "name")
        #expect(PropertyKey(Person.CodingKeys.name) == key)
        let data = try JSONEncoder().encode(key)
        #expect(try JSONDecoder().decode(PropertyKey.self, from: data) == key)
    }

    @Test func entityDefaultImplementations() {
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
        #expect(Empty.entityName.rawValue == "Empty")
        #expect(Empty.attributes == [:])
        #expect(Empty.relationships == [:])
        let description = EntityDescription(entity: Empty.self)
        #expect(description.id == Empty.entityName)
        #expect(description.attributes == [])
        #expect(description.relationships == [])
    }

    @Test func modelDataCodable() throws {
        var data = ModelData(entity: "Person", id: "1")
        data.encode("Alice", forKey: PredicateCodingTests.Key.name)
        data.encodeRelationship([UUID()], forKey: PredicateCodingTests.Key.age)
        let encoded = try JSONEncoder().encode(data)
        let decoded = try JSONDecoder().decode(ModelData.self, from: encoded)
        #expect(decoded == data)
    }

    #if canImport(CoreData)
    @Test func nsNumberConversion() {
        #expect(NSNumber(value: .bool(true)) == NSNumber(value: true))
        #expect(NSNumber(value: .int16(16)) == NSNumber(value: Int16(16)))
        #expect(NSNumber(value: .int32(32)) == NSNumber(value: Int32(32)))
        #expect(NSNumber(value: .int64(64)) == NSNumber(value: Int64(64)))
        #expect(NSNumber(value: .float(1.5)) == NSNumber(value: Float(1.5)))
        #expect(NSNumber(value: .double(2.5)) == NSNumber(value: Double(2.5)))
        #expect(NSNumber(value: .string("x")) == nil)
        #expect(NSNumber(value: .null) == nil)
    }
    #endif
}
