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
    
    @CompositeAttribute
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
    
    @CompositeAttribute
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

extension Campground.LocationCoordinates: CompositeAttributeCodable {

    public enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }

    public static var attributeElements: [Attribute] {
        [
            Attribute(id: PropertyKey(CodingKeys.latitude), type: .double),
            Attribute(id: PropertyKey(CodingKeys.longitude), type: .double)
        ]
    }

    public var compositeValue: [PropertyKey: AttributeValue] {
        var value = [PropertyKey: AttributeValue]()
        value.encode(latitude, forKey: CodingKeys.latitude)
        value.encode(longitude, forKey: CodingKeys.longitude)
        return value
    }

    public init?(compositeValue: [PropertyKey: AttributeValue]) {
        guard let latitude = compositeValue.decode(Double.self, forKey: CodingKeys.latitude),
            let longitude = compositeValue.decode(Double.self, forKey: CodingKeys.longitude) else {
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

extension Campground.Schedule: CompositeAttributeCodable {

    public enum CodingKeys: String, CodingKey {
        case start
        case end
    }

    public static var attributeElements: [Attribute] {
        [
            // - Note: `.int64`, since `UInt.attributeValue` is `.int64`.
            Attribute(id: PropertyKey(CodingKeys.start), type: .int64),
            Attribute(id: PropertyKey(CodingKeys.end), type: .int64)
        ]
    }

    public var compositeValue: [PropertyKey: AttributeValue] {
        var value = [PropertyKey: AttributeValue]()
        value.encode(start, forKey: CodingKeys.start)
        value.encode(end, forKey: CodingKeys.end)
        return value
    }

    public init?(compositeValue: [PropertyKey: AttributeValue]) {
        guard let start = compositeValue.decode(UInt.self, forKey: CodingKeys.start),
            let end = compositeValue.decode(UInt.self, forKey: CodingKeys.end) else {
            return nil
        }
        // - Note: Assigns the stored properties directly rather than calling
        //   `init(start:end:)`, whose `assert(start < end)` would trap in debug builds
        //   when decoding arbitrary stored data.
        self.start = start
        self.end = end
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
        
        @CompositeAttribute
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
