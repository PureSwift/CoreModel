//
//  SortDescriptorTests.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 10/21/25.
//

#if canImport(Darwin)
import Foundation
import Testing
@testable import CoreModel
@testable import CoreDataModel

@Suite struct SortDescriptorTests {
    
    @Test func foundation() {
        
        let events = [
            EventObject(
                id: 2,
                name: "Event 2",
                start: Date(timeIntervalSince1970: 60 * 60 * 2),
                speakers: [
                    PersonObject(
                        id: 2,
                        name: "John Apple"
                    )
            ]),
            EventObject(
                id: 3,
                name: "Event 3",
                start: Date(timeIntervalSince1970: 60 * 60 * 4),
                speakers: [
                    PersonObject(
                        id: 1,
                        name: "Alsey Coleman Miller"
                    ),
                    PersonObject(
                        id: 2,
                        name: "John Apple"
                    )
            ]),
            EventObject(
                id: 1,
                name: "Event 1",
                start: Date(timeIntervalSince1970: 0),
                speakers: [
                    PersonObject(
                        id: 1,
                        name: "Alsey Coleman Miller"
                    )
            ])
        ]
        
        let sort = SortDescriptor(\EventObject.id, order: .forward)
        let sortDescriptor = FetchRequest.SortDescriptor(
            property: PropertyKey(EventObject.CodingKeys.id),
            ascending: true
        )
        let sortedEvents = events.sorted(using: sort)
        #expect(sortedEvents.map(\.id) == [1, 2, 3])
        #expect(sortDescriptor == FetchRequest.SortDescriptor(sort))
    }
}
#endif
