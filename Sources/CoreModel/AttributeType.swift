//
//  AttributeType.swift
//
//
//  Created by Alsey Coleman Miller on 8/16/23.
//

/// CoreModel Attribute type
public enum AttributeType: String, CaseIterable, Sendable {
    
    /// Boolean number type.
    case bool
    
    /// 16 bit Integer number type.
    case int16
    
    /// Integer number type.
    case int32
    
    /// Integer number type.
    case int64
    
    /// Floating point number type.
    case float
    
    /// Floating point number type.
    case double
    
    /// Attribute is a string.
    case string
    
    /// Attribute is binary data.
    case data
    
    /// Attribute is a date.
    case date
    
    /// UUID
    case uuid
    
    /// URL
    case url
    
    /// Decimal
    case decimal
}

// MARK: - Codable

#if !hasFeature(Embedded)
extension AttributeType: Codable {}
#endif
