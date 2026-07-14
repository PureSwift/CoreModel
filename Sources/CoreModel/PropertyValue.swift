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
