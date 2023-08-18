//
//  CoreDataTests.swift
//  
//
//  Created by Alsey Coleman Miller on 8/17/23.
//

#if canImport(CoreData)

import Foundation
import CoreData
import XCTest
import Predicate
@testable import CoreModel
@testable import CoreDataModel

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
final class CoreDataTests: XCTestCase {
    
    func testCoreData() async throws {
        
        let model = Model(entities: Person.self, Event.self)
        
        let store = NSPersistentContainer(
            name: "Test\(UUID())",
            managedObjectModel: NSManagedObjectModel(model: model)
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
        
        let event1Data = try event1.encode(log: { print("CoreModel Encoder:", $0) })
        try await store.insert(event1Data)
        person1 = try await store.fetch(Person.self, for: person1.id)!
        XCTAssertEqual(person1.events, [event1.id])
        event1 = try await store.fetch(Event.self, for: event1.id)!
        XCTAssertEqual(event1.people, [person1.id])
    }
}

#endif
