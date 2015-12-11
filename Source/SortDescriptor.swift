//
//  SortDescriptor.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/25/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import SwiftFoundation

public struct SortDescriptor: JSONEncodable, JSONDecodable {
    
    public var ascending: Bool
    
    public var propertyName: String
    
    public init(propertyName: String, ascending: Bool = true) {
        
        self.propertyName = propertyName
        self.ascending = ascending
    }
}

// MARK: - JSON

public extension SortDescriptor {
    
    init?(JSONValue: JSON.Value) {
        
        guard let jsonObject = JSONValue.objectValue where jsonObject.count == 1,
            let (key, jsonValue) = jsonObject.first,
            let ascending = jsonValue.rawValue as? Bool
            else { return nil }
        
        self.propertyName = key
        self.ascending = ascending
    }
    
    func toJSON() -> JSON.Value {
        
        return JSON.Value.Object([propertyName: JSON.Value.Number(.Boolean(ascending))])
    }
}
