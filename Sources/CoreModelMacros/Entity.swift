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
    
    public static var expansionNames: [String] {
        [
            "entityName",
            "attributes",
            "relationships"
        ]
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let entityNameDeclarationSyntax = try entityNameDeclarationSyntax(of: node, providingMembersOf: declaration, in: context)
        let attributesDeclarationSyntax = try attributesDeclarationSyntax(of: node, providingMembersOf: declaration, in: context)
        let relationshipsDeclarationSyntax = try relationshipsDeclarationSyntax(of: node, providingMembersOf: declaration, in: context)
        return [
            entityNameDeclarationSyntax,
            attributesDeclarationSyntax,
            relationshipsDeclarationSyntax
        ]
    }
}

extension EntityMacro {
    
    public static func typeName(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> String {
        // Extract type name
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
        return typeName
    }
    
    public static func explicitEntityName(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> String? {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self),
              let first = arguments.first else {
            return nil
        }
        return first.expression.description.trimmingCharacters(in: .punctuationCharacters)
    }
    
    public static func entityNameDeclarationSyntax(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> DeclSyntax {
        let entityName: String
        if let entityNameArgument = try explicitEntityName(of: node, providingMembersOf: declaration, in: context) {
            entityName = entityNameArgument
        } else {
            entityName = try typeName(of: node, providingMembersOf: declaration, in: context)
        }
        let entityNameDecl = """
        static var entityName: String { "\(entityName)" }
        """
        return DeclSyntax(stringLiteral: entityNameDecl)
    }
    
    public static func attributesDeclarationSyntax(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> DeclSyntax {
        // Collect @Attribute properties with metadata
        var attributeEntries: [String] = []
        
        for member in declaration.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  let binding = varDecl.bindings.first,
                  let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                  let typeSyntax = binding.typeAnnotation?.type
                  else { continue }

            let attributes = varDecl.attributes
            
            let typeName = typeSyntax.description.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let inferredType: String?

            switch typeName {
            case "String":
                inferredType = ".string"
            case "Data":
                inferredType = ".data"
            case "Bool":
                inferredType = ".bool"
            case "Int16":
                inferredType = ".int16"
            case "Int32":
                inferredType = ".int32"
            case "Int64":
                inferredType = ".int64"
            case "Int":
                inferredType = ".int64"
            case "Float":
                inferredType = ".float"
            case "Double":
                inferredType = ".double"
            case "Date":
                inferredType = ".date"
            case "UUID":
                inferredType = ".uuid"
            case "URL":
                inferredType = ".url"
            case "Decimal":
                inferredType = ".decimal"
            default:
                inferredType = nil
            }
            
            for attr in attributes.compactMap({ $0.as(AttributeSyntax.self) }) {
                if attr.attributeName.description == "Attribute" {
                    let type: String
                    if let argument = attr.argument?.description.trimmingCharacters(in: .whitespacesAndNewlines) {
                        // Use explicit parameter
                        type = argument
                    } else if let inferredType {
                        // Use inferred type
                        type = inferredType
                    } else {
                        throw MacroError.unknownAttributeType(for: identifier)
                    }
                    attributeEntries.append(".\(identifier): \(type)")
                }
            }
        }

        let attributesDecl = """
        static var attributes: [CodingKeys: AttributeType] {
            [\n                \(attributeEntries.joined(separator: ",\n                "))
            ]
        }
        """
        return DeclSyntax(stringLiteral: attributesDecl)
    }
    
    public static func relationshipsDeclarationSyntax(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> DeclSyntax {
        
        let relationshipsDecl = """
        static var relationships: [CodingKeys: RelationshipType] {
            [:]
        }
        """
        
        return DeclSyntax(stringLiteral: relationshipsDecl)
    }
}
