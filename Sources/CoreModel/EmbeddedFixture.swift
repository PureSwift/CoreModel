//
//  EmbeddedFixture.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/18/26.
//

// - Note: A concrete `Entity` conformance that only exists under Embedded Swift.
//   It forces the compiler to specialize the generic `Entity.init(from:)` /
//   `ModelData.decode(...)` / `decodeRelationship(...)` decode path for a real
//   conforming type — the exact instantiation the wasm-embedded CI job never
//   exercises through the test target. Without it, error-boxing regressions in
//   that path (`#EmbeddedRestrictions`) can silently reappear. Dead weight on
//   non-Embedded builds, so it is gated out entirely there.

#if hasFeature(Embedded)

#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

private struct EmbeddedEntityFixture: Entity {

    let id: UUID

    static var entityName: EntityName { "EmbeddedEntityFixture" }

    static var attributes: [CodingKeys: AttributeType] { [:] }

    static var relationships: [CodingKeys: Relationship] { [:] }

    enum CodingKeys: String, CodingKey { case id }

    init(from model: ModelData) throws(ModelDataDecodingError) {
        guard let id = Self.ID(objectID: model.id) else {
            throw .invalidIdentifier(model.id)
        }
        self.id = id
    }

    func encode() -> ModelData {
        ModelData(entity: Self.entityName, id: ObjectID(id))
    }
}

#endif
