//
//  Macros.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/17/25.
//

import Foundation
import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct Plugins: CompilerPlugin {
    
    let providingMacros: [Macro.Type] = [
        EntityMacro.self,
        RelationshipMacro.self,
        AttributeMacro.self
    ]
}
