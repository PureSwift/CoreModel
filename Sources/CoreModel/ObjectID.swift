//
//  ObjectID.swift
//  
//
//  Created by Alsey Coleman Miller on 8/17/23.
//

import Foundation

/// CoreModel Object Identifier
public struct ObjectID: RawRepresentable, Codable, Equatable, Hashable, Sendable {
    
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

// MARK: - ExpressibleByStringLiteral

extension ObjectID: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

// MARK: - CustomStringConvertible

extension ObjectID: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        rawValue
    }
    
    public var debugDescription: String {
        rawValue
    }
}

// MARK: - Supporting Types

public protocol ObjectIDConvertible: CustomStringConvertible {
    
    init?(objectID: ObjectID)
}

public extension ObjectID {
    
    init<T>(_ value: T) where T: ObjectIDConvertible {
        self.init(rawValue: value.description)
    }
}

extension UUID: ObjectIDConvertible {
    
    public init?(objectID: ObjectID) {
        self.init(uuidString: objectID.rawValue)
    }
}

extension String: ObjectIDConvertible {
    
    public init(objectID: ObjectID) {
        self = objectID.rawValue
    }
}

extension ObjectIDConvertible where Self: RawRepresentable, Self.RawValue == String {
    
    public init?(objectID: ObjectID) {
        self.init(rawValue: objectID.rawValue)
    }
}
