//
//  Entity.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/17/25.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// `@Entity` macro
///
/// Adds protocol conformance and implementaion for entity name.
public struct EntityMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        // get type name
        let typeName: String
        if let structDecl = declaration.as(StructDeclSyntax.self) {
            typeName = structDecl.name.text
        } else if let classDecl = declaration.as(ClassDeclSyntax.self) {
            typeName = classDecl.name.text
        } else if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            typeName = enumDecl.name.text
        } else {
            throw MacroError.invalidType
        }
        
        // Extract optional entity name
        let nameArg = (node.arguments?.firstToken(viewMode: .sourceAccurate) as? LabeledExprListSyntax)?
            .first?
            .expression
            .description
            .trimmingCharacters(in: .punctuationCharacters)
        
        let entityName = nameArg ?? typeName

        let entityNameDecl = """
        static var entityName: String { "\(entityName)" }
        """

        // Collect @Attribute properties with metadata
        var attributeEntries: [String] = []
/*
        for member in declaration.memberBlock {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  let binding = varDecl.bindings.first,
                  let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                  let typeSyntax = binding.typeAnnotation?.type,
                  let attributes = varDecl.attributes else { continue }

            let typeName = typeSyntax.description.trimmingCharacters(in: .whitespacesAndNewlines)
            let inferredType: String

            if typeName.hasPrefix("Optional") || typeName.hasSuffix("?") {
                inferredType = ".optional"
            } else if typeName == "String" {
                inferredType = ".string"
            } else if typeName == "Int" || typeName == "Int64" || typeName == "Int32" {
                inferredType = ".integer"
            } else if typeName == "Double" || typeName == "Float" {
                inferredType = ".float"
            } else if typeName == "Bool" {
                inferredType = ".boolean"
            } else if typeName == "Date" {
                inferredType = ".date"
            } else {
                inferredType = ".unsupported(\"\(typeName)\")"
            }

            for attr in attributes.compactMap({ $0.as(AttributeSyntax.self) }) {
                if attr.attributeName.description == "Attribute" {
                    if let argument = attr.argument?.description.trimmingCharacters(in: .whitespacesAndNewlines) {
                        // Use explicit parameter
                        attributeEntries.append(".\(identifier): \(argument)")
                    } else {
                        // Use inferred type
                        attributeEntries.append(".\(identifier): AttributeType(\(inferredType))")
                    }
                }
            }
        }*/

        let attributesDecl = """
        static var attributes: [CodingKeys: AttributeType] {
            [\n                \(attributeEntries.joined(separator: ",\n                "))
            ]
        }
        """

        return [
            DeclSyntax(stringLiteral: entityNameDecl),
            DeclSyntax(stringLiteral: attributesDecl)
        ]
    }
}

