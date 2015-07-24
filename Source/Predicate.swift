//
//  Predicate.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/25/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

public protocol Predicate {
    
    var predicateType: PredicateType { get }
}

public enum PredicateType: String {
    
    case Comparison
    case Compound
}