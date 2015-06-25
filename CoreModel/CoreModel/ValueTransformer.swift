//
//  Transformable.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public protocol ValueTransformer {
    
    typealias T
    
    var identifier: String { get }
    
    func toData() -> [UInt8]
    
    func fromData() -> T?
}