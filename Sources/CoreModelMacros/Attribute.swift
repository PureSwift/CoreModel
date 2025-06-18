//
//  Attribute.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/17/25.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct AttributeMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        // Tag only, logic handled in EntityMacro
        return []
    }
}

internal func inferAttributeType(from type: String) -> String? {
    switch type {
        case "String": return ".string"
        case "Data": return ".data"
        case "Bool": return ".bool"
        case "Int16": return ".int16"
        case "Int32": return ".int32"
        case "Int64": return ".int64"
        case "Int": return ".int64"
        case "Float": return ".float"
        case "Double": return ".double"
        case "Date": return ".date"
        case "UUID": return ".uuid"
        case "URL": return ".url"
        case "Decimal": return ".decimal"
        default: return nil
    }
}
