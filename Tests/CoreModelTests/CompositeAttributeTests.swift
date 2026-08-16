//
//  CompositeAttributeTests.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 8/16/26.
//

import Foundation
import Testing
@testable import CoreModel

@Suite struct CompositeAttributeTests {

    enum Key: CodingKey {
        case value
    }

    /// A composite whose elements include another composite.
    struct Address: CompositeAttributeCodable, Equatable, Hashable {

        var street: String
        var location: Campground.LocationCoordinates

        enum CodingKeys: String, CodingKey {
            case street
            case location
        }

        static var attributeElements: [Attribute] {
            [
                Attribute(id: PropertyKey(CodingKeys.street), type: .string),
                Attribute(id: PropertyKey(CodingKeys.location), composite: Campground.LocationCoordinates.self)
            ]
        }

        var compositeValue: [PropertyKey: AttributeValue] {
            var value = [PropertyKey: AttributeValue]()
            value.encode(street, forKey: CodingKeys.street)
            value.encode(location, forKey: CodingKeys.location)
            return value
        }

        init(street: String, location: Campground.LocationCoordinates) {
            self.street = street
            self.location = location
        }

        init?(compositeValue: [PropertyKey: AttributeValue]) {
            guard let street = compositeValue.decode(String.self, forKey: CodingKeys.street),
                let location = compositeValue.decode(Campground.LocationCoordinates.self, forKey: CodingKeys.location) else {
                return nil
            }
            self.init(street: street, location: location)
        }
    }

    static let coordinates = Campground.LocationCoordinates(latitude: 34.51446212994721, longitude: -89.15318142250365)

    static var coordinatesValue: AttributeValue {
        .composite([
            "latitude": .double(34.51446212994721),
            "longitude": .double(-89.15318142250365)
        ])
    }

    // MARK: - Encoding

    @Test func encodeComposite() {
        #expect(Self.coordinates.attributeValue == Self.coordinatesValue)
        #expect(Campground.LocationCoordinates.attributeType == .composite([
            Attribute(id: "latitude", type: .double),
            Attribute(id: "longitude", type: .double)
        ]))
    }

    @Test func decodeComposite() {
        #expect(Campground.LocationCoordinates(attributeValue: Self.coordinatesValue) == Self.coordinates)
    }

    @Test func decodeInvalidComposite() {
        // not a composite at all
        #expect(Campground.LocationCoordinates(attributeValue: .string("34.5,-89.1")) == nil)
        #expect(Campground.LocationCoordinates(attributeValue: .null) == nil)
        // element of the wrong type
        #expect(Campground.LocationCoordinates(attributeValue: .composite([
            "latitude": .string("34.5"),
            "longitude": .double(-89.1)
        ])) == nil)
        // missing element
        #expect(Campground.LocationCoordinates(attributeValue: .composite([
            "latitude": .double(34.5)
        ])) == nil)
        // element explicitly null
        #expect(Campground.LocationCoordinates(attributeValue: .composite([
            "latitude": .double(34.5),
            "longitude": .null
        ])) == nil)
    }

    @Test func optionalComposite() {
        let none: Campground.LocationCoordinates? = nil
        #expect(none.attributeValue == .null)
        #expect(Campground.LocationCoordinates?(attributeValue: .null) == .some(.none))
        let some: Campground.LocationCoordinates? = Self.coordinates
        #expect(some.attributeValue == Self.coordinatesValue)
    }

    @Test func nestedComposite() {
        let address = Address(street: "1 Main", location: Self.coordinates)
        let expected = AttributeValue.composite([
            "street": .string("1 Main"),
            "location": Self.coordinatesValue
        ])
        #expect(address.attributeValue == expected)
        #expect(Address(attributeValue: expected) == address)
        // the element list nests too
        #expect(Address.attributeType == .composite([
            Attribute(id: "street", type: .string),
            Attribute(id: "location", type: Campground.LocationCoordinates.attributeType)
        ]))
    }

    // MARK: - ModelData

    @Test func modelDataRoundTrip() throws {
        var data = ModelData(entity: "Test", id: "1")
        data.encode(Self.coordinates, forKey: Key.value)
        #expect(data.attributes[.init(Key.value)] == Self.coordinatesValue)
        let decoded = try data.decode(Campground.LocationCoordinates.self, forKey: Key.value)
        #expect(decoded == Self.coordinates)
    }

    @Test func modelDataTypeMismatch() {
        var data = ModelData(entity: "Test", id: "1")
        data.encode("not a composite", forKey: Key.value)
        #expect(throws: (any Error).self) {
            try data.decode(Campground.LocationCoordinates.self, forKey: Key.value)
        }
    }

    /// `Schedule.init(start:end:)` asserts `start < end`, so decoding must assign the
    /// stored properties directly rather than route through it.
    @Test func decodeScheduleWithoutAssertion() {
        let value = AttributeValue.composite(["start": .int64(20), "end": .int64(5)])
        let schedule = Campground.Schedule(attributeValue: value)
        #expect(schedule?.start == 20)
        #expect(schedule?.end == 5)
    }

    // MARK: - Schema

    @Test func attributeElementLookup() {
        let attribute = Attribute(id: "location", composite: Campground.LocationCoordinates.self)
        #expect(attribute.elements?.count == 2)
        #expect(attribute[element: "latitude"]?.type == .double)
        #expect(attribute[element: "missing"] == nil)
        #expect(attribute.type.isComposite)
        // a scalar attribute has no elements
        #expect(Attribute(id: "name", type: .string).elements == nil)
        #expect(Attribute(id: "name", type: .string).type.isComposite == false)
    }

    @Test func entityDescriptionKeyPathResolution() {
        let entity = EntityDescription(entity: Campground.self)
        #expect(entity.attribute(for: "location")?.type == Campground.LocationCoordinates.attributeType)
        #expect(entity.attribute(for: "location.latitude")?.type == .double)
        #expect(entity.attribute(for: "officeHours.start")?.type == .int64)
        // paths that leave the attribute graph
        #expect(entity.attribute(for: "location.altitude") == nil)
        #expect(entity.attribute(for: "name.nope") == nil)
        #expect(entity.attribute(for: "units") == nil)
        #expect(entity.attribute(for: PredicateKeyPath(keys: [])) == nil)
    }

    @Test func scalarTypeBridge() {
        for type in AttributeType.scalarCases {
            let rawValue = try! #require(type.scalarRawValue)
            #expect(AttributeType(scalarRawValue: rawValue) == type)
        }
        #expect(AttributeType.scalarCases.count == 12)
        #expect(Campground.LocationCoordinates.attributeType.scalarRawValue == nil)
        #expect(AttributeType(scalarRawValue: "composite") == nil)
        #expect(AttributeType(scalarRawValue: "bogus") == nil)
    }

    // MARK: - Normalization

    @Test func normalizeComposite() {
        let elements = Campground.LocationCoordinates.attributeElements
        // a partially specified composite gains the elements it doesn't declare
        let partial = AttributeValue.composite(["latitude": .double(1)])
        #expect(partial.normalized(for: elements) == .composite([
            "latitude": .double(1),
            "longitude": .null
        ]))
        // an absent composite stays absent, rather than becoming a dictionary of nulls
        #expect(AttributeValue.null.normalized(for: elements) == .null)
        // undeclared elements are preserved
        let extra = AttributeValue.composite([
            "latitude": .double(1),
            "longitude": .double(2),
            "altitude": .double(3)
        ])
        #expect(extra.normalized(for: elements) == extra)
    }

    @Test func normalizeNestedComposite() {
        let partial = AttributeValue.composite(["street": .string("1 Main")])
        #expect(partial.normalized(for: Address.attributeElements) == .composite([
            "street": .string("1 Main"),
            "location": .null
        ]))
        // a present-but-partial nested composite is filled in one level down
        let nested = AttributeValue.composite([
            "street": .string("1 Main"),
            "location": .composite(["latitude": .double(1)])
        ])
        #expect(nested.normalized(for: Address.attributeElements) == .composite([
            "street": .string("1 Main"),
            "location": .composite(["latitude": .double(1), "longitude": .null])
        ]))
    }

    // MARK: - Comparison

    @Test func compositeComparison() {
        let value = Self.coordinatesValue
        // equality is recursive dictionary equality, and order independent
        #expect(AttributeValue.areEqual(value, Self.coordinates.attributeValue, caseInsensitive: false))
        #expect(AttributeValue.areEqual(value, .composite(["latitude": .double(1)]), caseInsensitive: false) == false)
        // composites are not orderable
        #expect(AttributeValue.order(value, .composite(["latitude": .double(1)])) == nil)
        // a composite of nulls is not itself null
        let allNull = PredicateValue.attribute(.composite(["latitude": .null]))
        #expect(allNull.isNull == false)
        #expect(PredicateValue.attribute(.null).isNull)
    }

    @Test func compositeDescription() {
        #expect(Campground.LocationCoordinates.attributeType.description == "composite(latitude: double, longitude: double)")
        #expect(AttributeType.string.description == "string")
        // rendered sorted by element name, so diagnostics are deterministic
        #expect(Self.coordinatesValue.predicateDescription == "{latitude = 34.51446212994721, longitude = -89.15318142250365}")
    }

    // MARK: - Codable

    @Test func attributeTypeCodable() throws {
        // scalars keep the pre-composite wire format
        for type in AttributeType.scalarCases {
            let data = try JSONEncoder().encode(type)
            #expect(String(data: data, encoding: .utf8) == "\"\(type.scalarRawValue!)\"")
            #expect(try JSONDecoder().decode(AttributeType.self, from: data) == type)
        }
        // composites, including nested ones, round trip
        for type in [Campground.LocationCoordinates.attributeType, Address.attributeType] {
            let data = try JSONEncoder().encode(type)
            #expect(try JSONDecoder().decode(AttributeType.self, from: data) == type)
        }
        // an unknown identifier is a decoding error, not a silent default
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(AttributeType.self, from: Data(#""bogus""#.utf8))
        }
    }

    /// An `Attribute` carrying a scalar type must encode exactly as it did before
    /// composite attributes existed, so persisted models stay readable.
    @Test func attributeWireCompatibility() throws {
        let attribute = Attribute(id: "name", type: .string)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let json = String(data: try encoder.encode(attribute), encoding: .utf8)
        #expect(json == #"{"id":"name","type":"string"}"#)
        #expect(try JSONDecoder().decode(Attribute.self, from: try encoder.encode(attribute)) == attribute)
    }

    @Test func modelCodable() throws {
        let model = Model(entities: [
            EntityDescription(entity: Campground.self),
            EntityDescription(entity: Campground.Unit.self)
        ])
        let data = try JSONEncoder().encode(model)
        #expect(try JSONDecoder().decode(Model.self, from: data) == model)
    }

    @Test func attributeValueCodable() throws {
        let value = AttributeValue.composite([
            "street": .string("1 Main"),
            "location": Self.coordinatesValue,
            "missing": .null
        ])
        let data = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(AttributeValue.self, from: data) == value)
    }
}
