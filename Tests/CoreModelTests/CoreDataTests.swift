//
//  CoreDataTests.swift
//  
//
//  Created by Alsey Coleman Miller on 8/17/23.
//

#if canImport(CoreData)

import Foundation
import CoreData
import Testing
@testable import CoreModel
@testable import CoreDataModel

@Suite
struct CoreDataTests {
    
    @available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
    @Test func coreData() async throws {
        
        let model = Model(
            entities:
                Person.self,
                Event.self,
                Campground.self,
                Campground.Unit.self
        )
        
        let managedObjectModel = NSManagedObjectModel(model: model)
        
        let store = NSPersistentContainer(
            name: "Test\(UUID())",
            managedObjectModel: managedObjectModel
        )
        
        for try await store in store.loadPersistentStores() {
            print("Loaded store", store.type, store.url?.absoluteString ?? "")
        }
        
        var person1 = Person(
            name: "John Appleseed",
            age: 22
        )
        
        try await store.insert(person1)
        
        var event1 = Event(
            name: "WWDC",
            date: Date(timeIntervalSinceNow: 60 * 60 * 24 * 10),
            people: [person1.id]
        )
        
        var event1Data = try event1.encode(log: { print("Encoder:", $0) })
        try await store.insert(event1Data)
        person1 = try await store.fetch(Person.self, for: person1.id)!
        #expect(person1.events == [event1.id])
        event1Data = try await store.fetch(Event.entityName, for: ObjectID(event1.id))!
        event1 = try .init(from: event1Data, log: { print("Decoder:", $0) })
        #expect(event1.people == [person1.id])
        
        var campground = Campground(
            name: "Fair Play RV Park",
            address: """
            243 Fisher Cove Rd,
            Fair Play, SC
            """,
            location: .init(latitude: 34.51446212994721, longitude: -83.01371101951648),
            descriptionText: """
            At Fair Play RV Park, we are committed to providing a clean, safe and fun environment for all of our guests, including your fur-babies! We look forward to meeting you and having you stay with us!
            """,
            officeHours: Campground.Schedule(start: 60 * 8, end: 60 * 18)
        )
        
        let rentalUnit = Campground.Unit(
            campground: campground.id,
            name: "A1",
            amenities: [.amp50, .water, .mail, .river, .laundry],
            checkout: campground.officeHours
        )
        
        var campgroundData = try campground.encode(log: { print("Encoder:", $0) })
        try await store.insert(campgroundData)
        let rentalUnitData = try rentalUnit.encode(log: { print("Encoder:", $0) })
        #expect(rentalUnitData.relationships[PropertyKey(Campground.Unit.CodingKeys.campground)] == .toOne(ObjectID(campground.id)))
        try await store.insert(rentalUnitData)
        campgroundData = try await store.fetch(Campground.entityName, for: ObjectID(campground.id))!
        campground = try .init(from: campgroundData, log: { print("Decoder:", $0) })
        #expect(campground.units == [rentalUnit.id])
        #expect(campgroundData.relationships[PropertyKey(Campground.CodingKeys.units)] == .toMany([ObjectID(rentalUnit.id)]))
        let fetchedRentalUnit = try await store.fetch(Campground.Unit.self, for: rentalUnit.id)
        #expect(fetchedRentalUnit == rentalUnit)
        
        let rentalUnitFetchRequest = FetchRequest(
            entity: Campground.Unit.entityName,
            predicate: Campground.Unit.CodingKeys.campground.stringValue.compare(.equalTo, .relationship(.toOne(ObjectID(campground.id))))
        )
        let rentalUnitIDs = try await store.fetchID(rentalUnitFetchRequest)
        #expect(rentalUnitIDs == campground.units.map { ObjectID($0) })
    }
}

#endif
