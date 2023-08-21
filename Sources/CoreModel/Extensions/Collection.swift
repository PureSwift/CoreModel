//
//  Collection.swift
//  
//
//  Created by Alsey Coleman Miller on 4/13/20.
//

import Foundation

internal extension Array where Element: Equatable {
    
    func begins(with other: Self) -> Bool {
        return prefix(other.count) == other[0 ..< other.count]
    }
}

internal extension Collection where Element: Equatable {
    
    func contains(_ other: Self) -> Bool {
        for element in other {
            guard contains(element) else { return false }
        }
        return true
    }
}
