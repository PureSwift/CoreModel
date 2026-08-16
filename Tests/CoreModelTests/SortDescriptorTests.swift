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

    @Test func foundationConversion() throws {

        let sortDescriptor = FetchRequest.SortDescriptor(
            property: PropertyKey(EventObject.CodingKeys.id),
            ascending: false
        )
        let foundationSort = try #require(sortDescriptor.toFoundation(comparing: EventObject.self))
        #expect(FetchRequest.SortDescriptor(foundationSort) == sortDescriptor)

        let events = [
            EventObject(id: 1, name: "Event 1", start: Date(timeIntervalSince1970: 0), speakers: []),
            EventObject(id: 3, name: "Event 3", start: Date(timeIntervalSince1970: 60), speakers: []),
            EventObject(id: 2, name: "Event 2", start: Date(timeIntervalSince1970: 30), speakers: [])
        ]
        let sortedEvents = events.sorted(using: foundationSort)
        #expect(sortedEvents.map(\.id) == [3, 2, 1])
    }

    @Test func nsSortDescriptor() throws {

        let sortDescriptor = FetchRequest.SortDescriptor(
            property: PropertyKey(EventObject.CodingKeys.name),
            ascending: true
        )
        let nsSortDescriptor = try #require(sortDescriptor.toFoundation())
        #expect(nsSortDescriptor.key == "name")
        #expect(nsSortDescriptor.ascending)
        #expect(FetchRequest.SortDescriptor(nsSortDescriptor) == sortDescriptor)

        // sort descriptors without a key path cannot be converted
        let comparatorSortDescriptor = NSSortDescriptor(key: nil, ascending: true)
        #expect(FetchRequest.SortDescriptor(comparatorSortDescriptor) == nil)
    }

    @Test func functionSortTerm() {

        // function-based sort terms have no Foundation equivalent
        let sortDescriptor = FetchRequest.SortDescriptor(
            term: .function(.init(name: "custom", arguments: [.keyPath("name")])),
            ascending: true
        )
        #expect(sortDescriptor.toFoundation() == nil)
        #expect(sortDescriptor.toFoundation(comparing: EventObject.self) == nil)
    }

    @Test func fetchRequest() {

        let fetchRequest = FetchRequest(
            entity: "Event",
            sortDescriptors: [
                SortDescriptor(\EventObject.start, order: .forward),
                SortDescriptor(\EventObject.id, order: .reverse)
            ]
        )
        #expect(fetchRequest.sortDescriptors == [
            FetchRequest.SortDescriptor(property: PropertyKey(EventObject.CodingKeys.start), ascending: true),
            FetchRequest.SortDescriptor(property: PropertyKey(EventObject.CodingKeys.id), ascending: false)
        ])
    }
}
#endif
