//
//  FoundationExtensions.swift
//  CoreModel
//
//  Created by Craig Radnovich on 11.12.2015.
//  Copyright © 2015 PureSwift. All rights reserved.
//

#if os(OSX)

import Foundation
import SwiftFoundation

extension NSData: DataConvertible {
    
    public func toData() -> Data {
        return arrayOfBytes()
    }
    
    public class func fromData(data: Data) -> DataConvertible {
        return NSData(bytes: data)
    }
}
    
    
extension DataConvertible {
    func toFoundation() -> AnyObject {
        
        return self as! AnyObject
    }
}


#endif