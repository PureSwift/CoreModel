//
//  Model.swift
//  
//
//  Created by Alsey Coleman Miller on 8/17/23.
//

import Foundation
import CoreModel

@Entity
struct Person: Equatable, Hashable, Codable, Identifiable {
    
    let id: UUID
    
    @Attribute
    var name: String
    
    @Attribute
    var created: Date
    
    @Attribute(.int16)
    var age: UInt
    
    @Relationship(destination: Event.self, inverse: .people)
    var events: [Event.ID]
    
    init(id: UUID = UUID(), name: String, created: Date = Date(), age: UInt, events: [Event.ID] = []) {
        self.id = id
        self.name = name
        self.created = created
        self.age = age
        self.events = events
    }
    
    enum CodingKeys: CodingKey {
        case id
        case name
        case created
        case age
        case events
    }
}

extension Person {
    
    init(from container: ModelData) throws {
        guard container.entity.rawValue == Self.entityName.rawValue else {
            throw DecodingError.typeMismatch(Self.self, DecodingError.Context(codingPath: [], debugDescription: "Cannot decode \(String(describing: Self.self)) from \(container.entity)"))
        }
        guard let id = UUID(uuidString: container.id.rawValue) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Cannot decode identifier from \(container.id)"))
        }
        self.id = id
        self.name = try container.decode(String.self, forKey: Person.CodingKeys.name)
        self.created = try container.decode(Date.self, forKey: Person.CodingKeys.created)
        self.age = try container.decode(UInt.self, forKey: Person.CodingKeys.age)
        self.events = try container.decodeRelationship([Event.ID].self, forKey: Person.CodingKeys.events)
    }
    
    func encode() -> ModelData {
        var container = ModelData(
            entity: Self.entityName,
            id: ObjectID(rawValue: self.id.description)
        )
        container.encode(self.name, forKey: Person.CodingKeys.name)
        container.encode(self.created, forKey: Person.CodingKeys.created)
        container.encode(self.age, forKey: Person.CodingKeys.age)
        container.encodeRelationship(self.events, forKey: Person.CodingKeys.events)
        return container
    }
}

@Entity
struct Event: Equatable, Hashable, Codable, Identifiable {
    
    let id: UUID
    
    @Attribute
    var name: String
    
    @Attribute
    var date: Date
    
    @Relationship(destination: Person.self, inverse: .events)
    var people: [Person.ID]
    
    init(id: UUID = UUID(), name: String, date: Date, people: [Person.ID] = []) {
        self.id = id
        self.name = name
        self.date = date
        self.people = people
    }
    
    enum CodingKeys: CodingKey {
        case id
        case name
        case date
        case people
    }
}

/// Campground Location
@Entity("Campground")
public struct Campground: Equatable, Hashable, Codable, Identifiable {
    
    public let id: UUID
    
    @Attribute
    public let created: Date
    
    @Attribute
    public let updated: Date
    
    @Attribute
    public var name: String
    
    @Attribute
    public var address: String
    
    @Attribute(.string)
    public var location: LocationCoordinates
    
    @Attribute(.string)
    public var amenities: [Amenity]
    
    @Attribute
    public var phoneNumber: String?
    
    @Attribute
    public var descriptionText: String
    
    /// The number of seconds from GMT.
    @Attribute(.int32)
    public var timeZone: Int
    
    @Attribute
    public var notes: String?
    
    @Attribute
    public var directions: String?
    
    @Attribute(.string)
    public var officeHours: Schedule
    
    @Relationship(destination: Unit.self, inverse: .campground)
    public var units: [Unit.ID]
    
    public init(
        id: UUID = UUID(),
        created: Date = Date(),
        updated: Date = Date(),
        name: String,
        address: String,
        location: LocationCoordinates,
        amenities: [Amenity] = [],
        phoneNumber: String? = nil,
        descriptionText: String,
        notes: String? = nil,
        directions: String? = nil,
        units: [Unit.ID] = [],
        timeZone: Int = 0,
        officeHours: Schedule
    ) {
        self.id = id
        self.created = created
        self.updated = updated
        self.name = name
        self.address = address
        self.location = location
        self.amenities = amenities
        self.phoneNumber = phoneNumber
        self.descriptionText = descriptionText
        self.notes = notes
        self.directions = directions
        self.units = units
        self.timeZone = timeZone
        self.officeHours = officeHours
    }
    
    public enum CodingKeys: CodingKey {
        case id
        case created
        case updated
        case name
        case address
        case location
        case amenities
        case phoneNumber
        case descriptionText
        case timeZone
        case notes
        case directions
        case units
        case officeHours
    }
}

public extension Campground {
    
    /// Campground Amenities
    enum Amenity: String, Codable, CaseIterable, Sendable {
        
        case water
        case amp30
        case amp50
        case wifi
        case laundry
        case mail
        case dumpStation
        case picnicArea
        case storage
        case cabins
        case showers
        case restrooms
        case pool
        case fishing
        case beach
        case lake
        case river
        case rv
        case tent
        case pets
    }
}

extension Array: AttributeEncodable where Self.Element == Campground.Amenity  {
    
    public var attributeValue: AttributeValue {
        let string = self.reduce("", { $0 + ($0.isEmpty ? "" : ",") + $1.rawValue })
        return .string(string)
    }
}

extension Array: AttributeDecodable where Self.Element == Campground.Amenity  {
    
    public init?(attributeValue: AttributeValue) {
        guard let string = String(attributeValue: attributeValue) else {
            return nil
        }
        let components = string
            .components(separatedBy: ",")
            .filter { $0.isEmpty == false }
        var values = [Campground.Amenity]()
        values.reserveCapacity(components.count)
        for element in components {
            guard let value = Self.Element(rawValue: element) else {
                return nil
            }
            values.append(value)
        }
        self = values
    }
}

public extension Campground {
    
    /// Location Coordinates
    struct LocationCoordinates: Equatable, Hashable, Codable, Sendable {
        
        /// Latitude
        public var latitude: Double
        
        /// Longitude
        public var longitude: Double
        
        public init(latitude: Double, longitude: Double) {
            self.latitude = latitude
            self.longitude = longitude
        }
    }
}

extension Campground.LocationCoordinates: AttributeEncodable {
    
    public var attributeValue: AttributeValue {
        return .string("\(latitude),\(longitude)")
    }
}

extension Campground.LocationCoordinates: AttributeDecodable {
    
    public init?(attributeValue: AttributeValue) {
        guard let string = String(attributeValue: attributeValue) else {
            return nil
        }
        let components = string.components(separatedBy: ",")
        guard components.count == 2,
            let latitude = Double(components[0]),
            let longitude = Double(components[1]) else {
            return nil
        }
        self.init(latitude: latitude, longitude: longitude)
    }
}

public extension Campground {
    
    /// Schedule (e.g. Check in, Check Out)
    struct Schedule: Equatable, Hashable, Codable, Sendable {
        
        public var start: UInt
        
        public var end: UInt
        
        public init(start: UInt, end: UInt) {
            assert(start < end)
            self.start = start
            self.end = end
        }
    }
}

extension Campground.Schedule: AttributeEncodable {
    
    public var attributeValue: AttributeValue {
        return .string("\(start),\(end)")
    }
}

extension Campground.Schedule: AttributeDecodable {
    
    public init?(attributeValue: AttributeValue) {
        guard let string = String(attributeValue: attributeValue) else {
            return nil
        }
        let components = string.components(separatedBy: ",")
        guard components.count == 2,
            let start = UInt(components[0]),
            let end = UInt(components[1]) else {
            return nil
        }
        self.init(start: start, end: end)
    }
}

public extension Campground {
    
    /// Campground Rental Unit
    @Entity("RentalUnit")
    struct Unit: Equatable, Hashable, Codable, Identifiable {
        
        public let id: UUID
        
        @Relationship(destination: Campground.self, inverse: .units)
        public let campground: Campground.ID
        
        @Attribute
        public var name: String
        
        @Attribute
        public var notes: String?
        
        @Attribute(.string)
        public var amenities: [Amenity]
        
        @Attribute(.string)
        public var checkout: Schedule
        
        public init(
            id: UUID = UUID(),
            campground: Campground.ID,
            name: String,
            notes: String? = nil,
            amenities: [Amenity] = [],
            checkout: Schedule
        ) {
            self.id = id
            self.campground = campground
            self.name = name
            self.notes = notes
            self.amenities = amenities
            self.checkout = checkout
        }
        
        public enum CodingKeys: CodingKey {
            
            case id
            case campground
            case name
            case notes
            case amenities
            case checkout
        }
    }
}
