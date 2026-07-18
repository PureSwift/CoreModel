//
//  StoreDefaultsTests.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/17/25.
//

import Foundation
import XCTest
@testable import CoreModel

/// Minimal in-memory `ModelStorage` conformer that relies on the protocol's
/// default implementations of `count(_:)` and `insert(_:)` for arrays.
private final class MinimalStore: ModelStorage, @unchecked Sendable {

    private var objects = [EntityName: [ObjectID: ModelData]]()

    func fetch(_ entity: EntityName, for id: ObjectID) async throws -> ModelData? {
        objects[entity]?[id]
    }

    func fetch(_ fetchRequest: FetchRequest) async throws -> [ModelData] {
        (objects[fetchRequest.entity] ?? [:])
            .values
            .sorted { $0.id.rawValue < $1.id.rawValue }
    }

    func fetchID(_ fetchRequest: FetchRequest) async throws -> [ObjectID] {
        try await fetch(fetchRequest).map { $0.id }
    }

    func insert(_ value: ModelData) async throws {
        objects[value.entity, default: [:]][value.id] = value
    }

    func delete(_ entity: EntityName, for id: ObjectID) async throws {
        objects[entity]?[id] = nil
    }

    func delete(_ entity: EntityName, for ids: [ObjectID]) async throws {
        for id in ids {
            try await delete(entity, for: id)
        }
    }

    func register(function: DatabaseFunction) async throws { }
}

final class StoreDefaultsTests: XCTestCase {

    func testDefaultImplementations() async throws {
        let store = MinimalStore()
        let people = [
            Person(name: "Alice", age: 30),
            Person(name: "Bob", age: 25)
        ]
        // default insert(_:) for arrays inserts one at a time
        try await store.insert(people.map { try! $0.encode() })
        // default count(_:) falls back to fetching and counting
        let count = try await store.count(FetchRequest(entity: Person.entityName))
        XCTAssertEqual(count, 2)
        // typed convenience still works through the defaults
        let fetched = try await store.fetch(Person.self, for: people[0].id)
        XCTAssertEqual(fetched, people[0])
    }
}
