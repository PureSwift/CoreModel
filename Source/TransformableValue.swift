//
//  FoundationExtensions.swift
//  CoreModel
//
//  Created by Craig Radnovich on 11.12.2015.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import SwiftFoundation

///  Transformable Attributes for **CoreModel** entities
///

func ==(lhs: DataConvertible, rhs: DataConvertible) -> Bool {
    return lhs.toData() == rhs.toData()
}

public protocol DataConvertible: JSONEncodable {
    func toData() -> Data
    static func fromData(data: Data) -> DataConvertible
}

extension JSON.Value {
    
    func parseTransformable() -> DataConvertible? {
        switch self {
        case let .String(amped):
            
            let keyAndData = amped.characters.split { $0 == "&" }.map(Swift.String.init)
            
            guard keyAndData.count == 2 else {
                fatalError("There should only be one key and one data section; instead there are \(keyAndData.count): \(keyAndData)")
            }
            
            guard let key = keyAndData.first,
                let b64 = keyAndData.last,
                let generator = InstantiatorRegistry.lookup(typeName: key) else {
                    return nil
            }
            
            let b64Data = b64.toUTF8Data()
            
            let decoded = Base64.decode(b64Data)
            
            return generator(decoded)
            
        default:
            return nil
        }
    }
}

extension DataConvertible {
    public func toJSON() -> JSON.Value {
        let key = "\(self.dynamicType)"
        let data = toData()
        
        guard let b64 = String(UTF8Data: Base64.encode(data)) else {
            fatalError("Failed to create a string from the Base64 encoded data: \(data)")
        }
            
        let jsonnedString = "\(key)&\(b64)"
        
        return JSON.Value.String(jsonnedString)
    }

    public init?(JSONValue: JSON.Value) {
        if let t = JSONValue.parseTransformable() as? Self {
            self = t
        } else {
            return nil
        }
    }
}

public typealias Instantiator = Data -> DataConvertible

public struct InstantiatorRegistry {
    private static var commonRegistry: InstantiatorRegistry = {
        return InstantiatorRegistry()
    }()
    
    private var instantiators: [String:Instantiator] = [:]
    
    public static func register(typeName key: String, instantiator: Instantiator) {
        commonRegistry.instantiators[key] = instantiator
    }
    
    public static func lookup(typeName key: String) -> Instantiator? {
        return commonRegistry.instantiators[key]
    }
    
    public static func deregister(typeName key: String) -> Instantiator? {
        return commonRegistry.instantiators.removeValueForKey(key)
    }
}
