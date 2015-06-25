//
//  JSONCodable.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/25/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public protocol JSONCodable {
    
    static func fromJSON(JSONObject: JSONObject) -> Self
    
    func toJSON() -> JSONObject
}

public typealias JSONObject = [String: AnyObject]