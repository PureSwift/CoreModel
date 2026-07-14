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
public struct EntityMacro: MemberMacro, ExtensionMacro {
    
    public static var expansionNames: [String] {
        [
            "entityName",
            "attributes",
            "relationships",
            "init(from:)",
            "encode()"
        ]
    }
    
    // Add protocol conformance via extension
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let extensionDecl = ExtensionDeclSyntax(
            leadingTrivia: nil,
            attributes: [],
            modifiers: [],
            extensionKeyword: .keyword(.extension),
            extendedType: TypeSyntax(type),
            inheritanceClause: InheritanceClauseSyntax(
                colon: .colonToken(trailingTrivia: .space),
                inheritedTypes: InheritedTypeListSyntax {
                    InheritedTypeSyntax(
                        type: TypeSyntax(stringLiteral: "CoreModel.Entity")
                    )
                }
            ),
            genericWhereClause: nil,
            memberBlock: MemberBlockSyntax(members: [])
        )
        return [extensionDecl]
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let entityNameDeclarationSyntax = try entityNameDeclarationSyntax(of: node, providingMembersOf: declaration, in: context)
        let attributesDeclarationSyntax = try attributesDeclarationSyntax(of: node, providingMembersOf: declaration, in: context)
        let relationshipsDeclarationSyntax = try relationshipsDeclarationSyntax(of: node, providingMembersOf: declaration, in: context)
        let initDeclarationSyntax = try initDeclarationSyntax(of: node, providingMembersOf: declaration, in: context)
        let encodeDeclarationSyntax = try encodeDeclarationSyntax(of: node, providingMembersOf: declaration, in: context)
        return [
            entityNameDeclarationSyntax,
            attributesDeclarationSyntax,
            relationshipsDeclarationSyntax,
            initDeclarationSyntax,
            encodeDeclarationSyntax
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
        public static var entityName: EntityName { "\(entityName)" }
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
            
            let rawTypeName = typeSyntax.description.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Strip Optional
            let typeName: String
            if rawTypeName.hasPrefix("Optional<") {
                typeName = rawTypeName
                    .replacingOccurrences(of: "Optional<", with: "")
                    .dropLast()
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            } else if rawTypeName.hasSuffix("?") {
                typeName = String(rawTypeName.dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                typeName = rawTypeName
            }
            
            let inferredType = inferAttributeType(from: typeName)
            
            for attr in attributes.compactMap({ $0.as(AttributeSyntax.self) }) {
                if attr.attributeName.description == "Attribute" {
                    let type: String
                    if let argument = attr.arguments?.description.trimmingCharacters(in: .whitespacesAndNewlines) {
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
        public static var attributes: [CodingKeys: AttributeType] {
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
        
        let entityName = try typeName(of: node, providingMembersOf: declaration, in: context)

        var relationshipEntries: [String] = []

        for member in declaration.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  let binding = varDecl.bindings.first,
                  let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                  let typeSyntax = binding.typeAnnotation?.type else { continue }

            
            let attributes = varDecl.attributes
            
            let rawType = typeSyntax.description.trimmingCharacters(in: .whitespacesAndNewlines)

            var relationshipType = ".toOne"
            var destinationType = rawType

            if rawType.hasPrefix("[") && rawType.hasSuffix("]") {
                relationshipType = ".toMany"
                destinationType = String(rawType.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
            }

            // Handle .ID suffix
            if destinationType.hasSuffix(".ID") {
                destinationType = String(destinationType.dropLast(3)) // remove ".ID"
            }

            for attr in attributes.compactMap({ $0.as(AttributeSyntax.self) }) {
                if attr.attributeName.description == "Relationship" {
      
                    guard let arguments = attr.arguments?.as(LabeledExprListSyntax.self),
                          let inverseArg = arguments.first(where: { $0.label?.text == "inverse" }) else {
                        throw MacroError.unknownInverseRelationship(for: identifier)
                    }

                    let inverseKeyName: String
                    
                    if let memberAccess = inverseArg.expression.as(MemberAccessExprSyntax.self) {
                        inverseKeyName = memberAccess.declName.baseName.text
                    } else if let keyPathExpr = inverseArg.expression.as(KeyPathExprSyntax.self),
                              let lastComponent = keyPathExpr.components.last {
                        inverseKeyName = lastComponent.description
                    } else {
                        throw MacroError.unknownInverseRelationship(for: identifier)
                    }
                    
                    let entry = """
                    .\(identifier): Relationship(
                        id: .\(identifier),
                        entity: \(entityName).self,
                        destination: \(destinationType).self,
                        type: \(relationshipType),
                        inverseRelationship: .\(inverseKeyName)
                    )
                    """
                    relationshipEntries.append(entry)
                }
            }
        }
        
        guard relationshipEntries.isEmpty == false else {
            return DeclSyntax(stringLiteral: #"public static var relationships: [CodingKeys: Relationship] { [:] }"#)
        }
        
        let relationshipsDecl = """
        public static var relationships: [CodingKeys: Relationship] {
            [\n            \(relationshipEntries.joined(separator: ",\n            "))
            ]
        }
        """

        return DeclSyntax(stringLiteral: relationshipsDecl)
    }

    /// Collects `@Attribute`/`@Relationship` properties as (name, raw type, isRelationship) tuples,
    /// in declaration order.
    public static func codableProperties(
        of declaration: some DeclGroupSyntax
    ) -> [(name: String, type: String, isRelationship: Bool)] {
        var properties: [(name: String, type: String, isRelationship: Bool)] = []
        for member in declaration.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  let binding = varDecl.bindings.first,
                  let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                  let typeSyntax = binding.typeAnnotation?.type
                  else { continue }
            let rawTypeName = typeSyntax.description.trimmingCharacters(in: .whitespacesAndNewlines)
            for attr in varDecl.attributes.compactMap({ $0.as(AttributeSyntax.self) }) {
                switch attr.attributeName.description {
                case "Attribute":
                    properties.append((identifier, rawTypeName, false))
                case "Relationship":
                    properties.append((identifier, rawTypeName, true))
                default:
                    continue
                }
            }
        }
        return properties
    }

    public static func initDeclarationSyntax(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> DeclSyntax {
        let typeName = try typeName(of: node, providingMembersOf: declaration, in: context)
        let lines = codableProperties(of: declaration).map { property -> String in
            if property.isRelationship {
                return "self.\(property.name) = try container.decodeRelationship(\(property.type).self, forKey: \(typeName).CodingKeys.\(property.name))"
            } else {
                return "self.\(property.name) = try container.decode(\(property.type).self, forKey: \(typeName).CodingKeys.\(property.name))"
            }
        }
        let body = lines.joined(separator: "\n        ")
        let initDecl = """
        public init(from container: ModelData) throws {
            guard container.entity.rawValue == Self.entityName.rawValue else {
                throw CoreModel.CoreModelError.invalidEntity(container.entity)
            }
            guard let id = Self.ID(objectID: container.id) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Cannot decode identifier from \\(container.id)"))
            }
            self.id = id
            \(body)
        }
        """
        return DeclSyntax(stringLiteral: initDecl)
    }

    public static func encodeDeclarationSyntax(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> DeclSyntax {
        let typeName = try typeName(of: node, providingMembersOf: declaration, in: context)
        let lines = codableProperties(of: declaration).map { property -> String in
            if property.isRelationship {
                return "container.encodeRelationship(self.\(property.name), forKey: \(typeName).CodingKeys.\(property.name))"
            } else {
                return "container.encode(self.\(property.name), forKey: \(typeName).CodingKeys.\(property.name))"
            }
        }
        let body = lines.joined(separator: "\n        ")
        let encodeDecl = """
        public func encode() -> ModelData {
            var container = ModelData(
                entity: Self.entityName,
                id: ObjectID(self.id)
            )
            \(body)
            return container
        }
        """
        return DeclSyntax(stringLiteral: encodeDecl)
    }

}
