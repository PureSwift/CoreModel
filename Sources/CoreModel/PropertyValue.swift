//
//  PropertyValue.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 11/4/18.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

// MARK: - Attribute

/// CoreModel Attribute Value
public enum AttributeValue: Equatable, Hashable, Sendable {

    case null
    case string(String)
    case uuid(UUID)
    case url(URL)
    case data(Data)
    case date(Date)
    case bool(Bool)
    case int16(Int16)
    case int32(Int32)
    case int64(Int64)
    case float(Float)
    case double(Double)
    case decimal(Decimal)

    /// The value of a composite attribute, keyed by the names of the ``Attribute``
    /// elements its ``AttributeType/composite(_:)`` declares.
    ///
    /// - Note: `.null` — not a dictionary of `.null` elements — is the canonical
    /// representation of an absent composite attribute.
    case composite([PropertyKey: AttributeValue])
}

// MARK: - Composite Normalization

public extension AttributeValue {

    /// Fill in the elements a composite value doesn't specify with `.null`, recursively.
    ///
    /// `.null` — what an absent composite attribute normalizes to — is returned
    /// unchanged: an absent composite is absent as a whole, not a dictionary of absent
    /// elements. Elements not declared by `elements` are preserved, matching how
    /// undeclared top-level attributes are treated.
    ///
    /// Storage backends should apply this when reading, so that a declared element is
    /// never missing from a composite that is itself present.
    func normalized(for elements: [Attribute]) -> AttributeValue {
        guard case let .composite(values) = self else {
            return self
        }
        // - Note: Explicit loop rather than `Dictionary.merge(_:uniquingKeysWith:)` —
        //   the closure-based overload does dynamic casting internally, which is
        //   disallowed under Embedded Swift.
        var normalized = values
        for element in elements {
            guard let value = normalized[element.id] else {
                normalized[element.id] = .null
                continue
            }
            guard case let .composite(nested) = element.type else { continue }
            normalized[element.id] = value.normalized(for: nested)
        }
        return .composite(normalized)
    }
}

// MARK: - Relationship

/// CoreModel Relationship Value
public enum RelationshipValue: Equatable, Hashable, Sendable {

    case null
    case toOne(ObjectID)
    case toMany([ObjectID])
}

// MARK: - Codable

#if !hasFeature(Embedded)
extension AttributeValue: Codable {}
extension RelationshipValue: Codable {}
#endif
