//
//  ValueJSON.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/23/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import SwiftFoundation

/// Converts the values object to JSON
public extension Entity {
    
    /// Converts ```JSON``` to *CoreModel* values. 
    ///
    /// - returns: The converted values or ```nil``` if the provided values do not match the entity's properties.
    func convert(values: JSONObject) -> ValuesObject? {
        
        return nil
    }
}

public extension JSON {
    
    /// Converts **CoreModel** values to ```JSON```.
    static func fromValues(values: ValuesObject) -> JSONObject {
        
        return JSONObject()
    }
}