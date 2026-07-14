//
//  EntityName.swift
//  
//
//  Created by Alsey Coleman Miller on 8/16/23.
//

public struct EntityName: RawRepresentable, Equatable, Hashable, Sendable {

    public let rawValue: String
    
    public init(rawValue: String) {
        assert(rawValue.isEmpty == false)
        self.rawValue = rawValue
    }
}

// MARK: - ExpressibleByStringLiteral

extension EntityName: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

// MARK: - CustomStringConvertible

extension EntityName: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        rawValue
    }
    
    public var debugDescription: String {
        rawValue
    }
}

// MARK: - Codable

#if !hasFeature(Embedded)
extension EntityName: Codable {}
#endif
