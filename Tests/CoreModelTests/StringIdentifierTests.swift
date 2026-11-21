//
//  StringIdentifierTests.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 10/29/26.
//

import Foundation
import Testing
@testable import CoreModel

@Suite struct StringIdentifierTests {

    static let model = Model(entities: [
        EntityDescription(entity: Tag.self)
    ])

    @Test func encodeDecode() throws {
        let tag = Tag(id: "swift", name: "Swift")
        let data = tag.encode()
        #expect(data.entity == "Tag")
        #expect(data.id == "swift")
        #expect(data.attributes["name"] == .string("Swift"))
        let decoded = try Tag(from: data)
        #expect(decoded == tag)
    }

    @Test func invalidEntity() {
        let data = ModelData(entity: "Person", id: "swift", attributes: ["name": .string("Swift")])
        #expect(throws: (any Error).self) {
            try Tag(from: data)
        }
    }

    @Test func insertAndFetch() async throws {
        let store = InMemoryModelStorage(model: Self.model)
        let tag = Tag(id: "swift", name: "Swift")
        try await store.insert(tag)
        let fetched = try await store.fetch(Tag.self, for: "swift")
        #expect(fetched == tag)
        let missing = try await store.fetch(Tag.self, for: "missing")
        #expect(missing == nil)
    }
}

/// Entity identified by a `String`, whose `init(objectID:)` is not failable.
@Entity
struct Tag: Equatable, Hashable, Codable, Identifiable {

    let id: String

    @Attribute
    var name: String

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}
