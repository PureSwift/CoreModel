//
//  PropertyValue.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 11/4/18.
//

import Foundation

/// CoreModel Attribute Value
public enum AttributeValue: Equatable, Hashable, Codable {
    
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
}

/// CoreModel Relationship Value
public enum RelationshipValue: Equatable, Hashable, Codable {
    
    case null
    case toOne(ObjectID)
    case toMany([ObjectID])
}
