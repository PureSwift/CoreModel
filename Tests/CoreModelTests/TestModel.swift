//
//  Model.swift
//  
//
//  Created by Alsey Coleman Miller on 8/17/23.
//

import Foundation
import CoreModel

struct Person: Equatable, Hashable, Codable, Identifiable {
    
    let id: UUID
    
    var name: String
    
    var created: Date
    
    var age: UInt
    
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
    
    init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<Person.CodingKeys> = try decoder.container(keyedBy: Person.CodingKeys.self)
        
        self.id = try container.decode(UUID.self, forKey: Person.CodingKeys.id)
        self.name = try container.decode(String.self, forKey: Person.CodingKeys.name)
        self.created = try container.decode(Date.self, forKey: Person.CodingKeys.created)
        self.age = try container.decode(UInt.self, forKey: Person.CodingKeys.age)
        self.events = try container.decode([Event.ID].self, forKey: Person.CodingKeys.events)
        
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Person.CodingKeys.self)
        
        try container.encode(self.id, forKey: Person.CodingKeys.id)
        try container.encode(self.name, forKey: Person.CodingKeys.name)
        try container.encode(self.created, forKey: Person.CodingKeys.created)
        try container.encode(self.age, forKey: Person.CodingKeys.age)
        try container.encode(self.events, forKey: Person.CodingKeys.events)
    }
}

extension Person: Entity {
    
    public static var entityName: EntityName { "Person" }
    
    static var attributes: [CodingKeys: AttributeType] {
        [
            .name: .string,
            .created: .date,
            .age: .int16
        ]
    }
    
    static var relationships: [CodingKeys: Relationship] {
        [
            .events: .init(
                id: PropertyKey(CodingKeys.events),
                type: .toMany,
                destinationEntity: Event.entityName,
                inverseRelationship: PropertyKey(Event.CodingKeys.people)
            )
        ]
    }
    
    init(from container: ModelData) throws {
        guard container.entity == Self.entityName else {
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

struct Event: Equatable, Hashable, Codable, Identifiable {
    
    let id: UUID
    
    var name: String
    
    var date: Date
    
    var people: [Person.ID]
    
    //var speaker: Person.ID?
    
    //var notes: String?
    
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
    
    init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<Event.CodingKeys> = try decoder.container(keyedBy: Event.CodingKeys.self)
        
        self.id = try container.decode(UUID.self, forKey: Event.CodingKeys.id)
        self.name = try container.decode(String.self, forKey: Event.CodingKeys.name)
        self.date = try container.decode(Date.self, forKey: Event.CodingKeys.date)
        self.people = try container.decode([Person.ID].self, forKey: Event.CodingKeys.people)
        
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Event.CodingKeys.self)
        
        try container.encode(self.id, forKey: Event.CodingKeys.id)
        try container.encode(self.name, forKey: Event.CodingKeys.name)
        try container.encode(self.date, forKey: Event.CodingKeys.date)
        try container.encode(self.people, forKey: Event.CodingKeys.people)
    }
}

extension Event: Entity {
    
    public static var entityName: EntityName { "Event" }
    
    static var attributes: [CodingKeys: AttributeType] {
        [
            .name: .string,
            .date: .date
        ]
    }
    
    static var relationships: [CodingKeys: Relationship] {
        [
            .people: .init(
                id: PropertyKey(CodingKeys.people),
                type: .toMany,
                destinationEntity: Person.entityName,
                inverseRelationship: PropertyKey(Person.CodingKeys.events))
        ]
    }
}
