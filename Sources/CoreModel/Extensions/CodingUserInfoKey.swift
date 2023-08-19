//
//  CodingUserInfoKey.swift
//  
//
//  Created by Alsey Coleman Miller on 8/19/23.
//

import Foundation

public extension CodingUserInfoKey {
    
    init(_ key: ModelCodingUserInfoKey) {
        self.init(rawValue: key.rawValue)!
    }
    
    static var identifierCodingKey: CodingUserInfoKey {
        .init(.identifierCodingKey)
    }
}

public enum ModelCodingUserInfoKey: String {
    
    case identifierCodingKey = "org.pureswift.CoreModel.CodingUserInfoKey.identifierCodingKey"
}
