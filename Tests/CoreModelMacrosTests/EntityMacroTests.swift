//
//  EntityMacroTests.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/17/25.
//

import Foundation
import XCTest
import SwiftSyntax
import SwiftParser
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion
@testable import CoreModelMacros

final class EntityMacroTests: XCTestCase {

    func testStructExpansion() throws {
        let (node, declaration) = try parse("""
        @Entity
        struct Person {
            var id: UUID
            @Attribute
            var name: String
            @Attribute
            var age: Int
            @Attribute
            var created: Date
        }
        """)
        let context = BasicMacroExpansionContext()
        let members = try expandMembers(of: node, attachedTo: declaration, in: context)
        XCTAssertEqual(members.count, 5)
        let source = members.map { $0.description }.joined(separator: "\n")
        XCTAssert(source.contains(#"public static var entityName: EntityName { "Person" }"#))
        XCTAssert(source.contains(".name: .string"))
        XCTAssert(source.contains(".age: .int64"))
        XCTAssert(source.contains(".created: .date"))
        XCTAssert(source.contains("public static var relationships: [CodingKeys: Relationship] { [:] }"))
        XCTAssert(source.contains("public init(from container: ModelData) throws"))
        XCTAssert(source.contains("self.name = try container.decode(String.self, forKey: Person.CodingKeys.name)"))
        XCTAssert(source.contains("public func encode() -> ModelData"))
        XCTAssert(source.contains("container.encode(self.age, forKey: Person.CodingKeys.age)"))
    }

    func testExtensionExpansion() throws {
        let (node, declaration) = try parse("""
        @Entity
        struct Person {
            var id: UUID
        }
        """)
        let context = BasicMacroExpansionContext()
        let extensions = try EntityMacro.expansion(
            of: node,
            attachedTo: declaration,
            providingExtensionsOf: TypeSyntax(stringLiteral: "Person"),
            conformingTo: [],
            in: context
        )
        XCTAssertEqual(extensions.count, 1)
        XCTAssert(extensions[0].description.contains("CoreModel.Entity"))
    }

    func testExplicitEntityName() throws {
        let (node, declaration) = try parse("""
        @Entity("PersonEntity")
        struct Person {
            var id: UUID
        }
        """)
        let context = BasicMacroExpansionContext()
        let decl = try EntityMacro.entityNameDeclarationSyntax(of: node, providingMembersOf: declaration, in: context)
        XCTAssert(decl.description.contains(#""PersonEntity""#))
    }

    func testOptionalAttributes() throws {
        let (node, declaration) = try parse("""
        @Entity
        struct Person {
            var id: UUID
            @Attribute
            var nickname: String?
            @Attribute
            var count: Optional<Int>
        }
        """)
        let context = BasicMacroExpansionContext()
        let decl = try EntityMacro.attributesDeclarationSyntax(of: node, providingMembersOf: declaration, in: context)
        XCTAssert(decl.description.contains(".nickname: .string"))
        XCTAssert(decl.description.contains(".count: .int64"))
    }

    func testExplicitAttributeType() throws {
        let (node, declaration) = try parse("""
        @Entity
        struct Person {
            var id: UUID
            @Attribute(.data)
            var avatar: CustomImage
        }
        """)
        let context = BasicMacroExpansionContext()
        let decl = try EntityMacro.attributesDeclarationSyntax(of: node, providingMembersOf: declaration, in: context)
        XCTAssert(decl.description.contains(".avatar: .data"))
    }

    func testUnknownAttributeType() throws {
        let (node, declaration) = try parse("""
        @Entity
        struct Person {
            var id: UUID
            @Attribute
            var point: CGPoint
        }
        """)
        let context = BasicMacroExpansionContext()
        XCTAssertThrowsError(try EntityMacro.attributesDeclarationSyntax(of: node, providingMembersOf: declaration, in: context)) { error in
            guard case MacroError.unknownAttributeType(let name) = error else {
                return XCTFail("Expected unknownAttributeType, got \(error)")
            }
            XCTAssertEqual(name, "point")
        }
    }

    func testRelationships() throws {
        let (node, declaration) = try parse("""
        @Entity
        struct Person {
            var id: UUID
            @Relationship(inverse: .owner)
            var pets: [Pet.ID]
            @Relationship(inverse: \\Company.employees)
            var employer: Company.ID?
        }
        """)
        let context = BasicMacroExpansionContext()
        let decl = try EntityMacro.relationshipsDeclarationSyntax(of: node, providingMembersOf: declaration, in: context)
        let source = decl.description
        XCTAssert(source.contains("destination: Pet.self"))
        XCTAssert(source.contains("type: .toMany"))
        XCTAssert(source.contains("inverseRelationship: .owner"))
        XCTAssert(source.contains("destination: Company.self"))
        XCTAssert(source.contains("type: .toOne"))
        XCTAssert(source.contains("inverseRelationship: .employees"))
    }

    func testMissingInverseRelationship() throws {
        let (node, declaration) = try parse("""
        @Entity
        struct Person {
            var id: UUID
            @Relationship
            var pets: [Pet.ID]
        }
        """)
        let context = BasicMacroExpansionContext()
        XCTAssertThrowsError(try EntityMacro.relationshipsDeclarationSyntax(of: node, providingMembersOf: declaration, in: context)) { error in
            guard case MacroError.unknownInverseRelationship(let name) = error else {
                return XCTFail("Expected unknownInverseRelationship, got \(error)")
            }
            XCTAssertEqual(name, "pets")
        }
    }

    func testInvalidInverseExpression() throws {
        let (node, declaration) = try parse("""
        @Entity
        struct Person {
            var id: UUID
            @Relationship(inverse: "owner")
            var pets: [Pet.ID]
        }
        """)
        let context = BasicMacroExpansionContext()
        XCTAssertThrowsError(try EntityMacro.relationshipsDeclarationSyntax(of: node, providingMembersOf: declaration, in: context)) { error in
            guard case MacroError.unknownInverseRelationship = error else {
                return XCTFail("Expected unknownInverseRelationship, got \(error)")
            }
        }
    }

    func testRelationshipDecodeEncode() throws {
        let (node, declaration) = try parse("""
        @Entity
        struct Person {
            var id: UUID
            @Attribute
            var name: String
            @Relationship(inverse: .owner)
            var pets: [Pet.ID]
        }
        """)
        let context = BasicMacroExpansionContext()
        let initDecl = try EntityMacro.initDeclarationSyntax(of: node, providingMembersOf: declaration, in: context)
        XCTAssert(initDecl.description.contains("self.pets = try container.decodeRelationship([Pet.ID].self, forKey: Person.CodingKeys.pets)"))
        let encodeDecl = try EntityMacro.encodeDeclarationSyntax(of: node, providingMembersOf: declaration, in: context)
        XCTAssert(encodeDecl.description.contains("container.encodeRelationship(self.pets, forKey: Person.CodingKeys.pets)"))
    }

    func testUnrelatedPropertyAttributeIgnored() throws {
        let (node, declaration) = try parse("""
        @Entity
        struct Person {
            var id: UUID
            @Attribute
            var name: String
            @Published
            var ignored: Int
        }
        """)
        let context = BasicMacroExpansionContext()
        let properties = EntityMacro.codableProperties(of: declaration)
        XCTAssertEqual(properties.map { $0.name }, ["name"])
        let initDecl = try EntityMacro.initDeclarationSyntax(of: node, providingMembersOf: declaration, in: context)
        XCTAssertFalse(initDecl.description.contains("ignored"))
    }

    func testClassTypeName() throws {
        let (node, declaration) = try parse("""
        @Entity
        class Animal {
            var id: UUID = UUID()
        }
        """)
        let context = BasicMacroExpansionContext()
        XCTAssertEqual(try EntityMacro.typeName(of: node, providingMembersOf: declaration, in: context), "Animal")
    }

    func testEnumTypeName() throws {
        let (node, declaration) = try parse("""
        @Entity
        enum Kind {
            case dog
        }
        """)
        let context = BasicMacroExpansionContext()
        XCTAssertEqual(try EntityMacro.typeName(of: node, providingMembersOf: declaration, in: context), "Kind")
    }

    func testInvalidType() throws {
        let (node, declaration) = try parse("""
        @Entity
        actor Worker {
            var id: UUID = UUID()
        }
        """)
        let context = BasicMacroExpansionContext()
        XCTAssertThrowsError(try EntityMacro.typeName(of: node, providingMembersOf: declaration, in: context)) { error in
            guard case MacroError.invalidType = error else {
                return XCTFail("Expected invalidType, got \(error)")
            }
        }
    }

    func testInferAttributeType() {
        XCTAssertEqual(inferAttributeType(from: "String"), ".string")
        XCTAssertEqual(inferAttributeType(from: "Data"), ".data")
        XCTAssertEqual(inferAttributeType(from: "Bool"), ".bool")
        XCTAssertEqual(inferAttributeType(from: "Int16"), ".int16")
        XCTAssertEqual(inferAttributeType(from: "Int32"), ".int32")
        XCTAssertEqual(inferAttributeType(from: "Int64"), ".int64")
        XCTAssertEqual(inferAttributeType(from: "Int"), ".int64")
        XCTAssertEqual(inferAttributeType(from: "Float"), ".float")
        XCTAssertEqual(inferAttributeType(from: "Double"), ".double")
        XCTAssertEqual(inferAttributeType(from: "Date"), ".date")
        XCTAssertEqual(inferAttributeType(from: "UUID"), ".uuid")
        XCTAssertEqual(inferAttributeType(from: "URL"), ".url")
        XCTAssertEqual(inferAttributeType(from: "Decimal"), ".decimal")
        XCTAssertNil(inferAttributeType(from: "CGPoint"))
    }

    func testPeerMacrosExpandToNothing() throws {
        let (node, declaration) = try parse("""
        @Entity
        struct Person {
            var id: UUID
        }
        """)
        let context = BasicMacroExpansionContext()
        XCTAssertEqual(try AttributeMacro.expansion(of: node, providingPeersOf: declaration, in: context).count, 0)
        XCTAssertEqual(try RelationshipMacro.expansion(of: node, providingPeersOf: declaration, in: context).count, 0)
    }

    func testExpansionNames() {
        XCTAssertEqual(EntityMacro.expansionNames.count, 5)
    }

    #if canImport(Darwin)
    func testMacroErrorDescriptions() {
        XCTAssertNotNil(MacroError.invalidType.errorDescription)
        XCTAssertNotNil(MacroError.unknownAttributeType(for: "point").errorDescription)
        XCTAssertNotNil(MacroError.unknownInverseRelationship(for: "pets").errorDescription)
    }
    #endif
}

// MARK: - Helpers

private extension EntityMacroTests {

    /// Parse source containing a single attributed type declaration, returning the
    /// macro attribute node and the declaration group it is attached to.
    func parse(_ source: String) throws -> (AttributeSyntax, any DeclGroupSyntax) {
        let file = Parser.parse(source: source)
        guard let decl = file.statements.first?.item.as(DeclSyntax.self) else {
            throw MacroError.invalidType
        }
        let group: (any DeclGroupSyntax)?
        let attributes: AttributeListSyntax
        if let structDecl = decl.as(StructDeclSyntax.self) {
            group = structDecl
            attributes = structDecl.attributes
        } else if let classDecl = decl.as(ClassDeclSyntax.self) {
            group = classDecl
            attributes = classDecl.attributes
        } else if let enumDecl = decl.as(EnumDeclSyntax.self) {
            group = enumDecl
            attributes = enumDecl.attributes
        } else if let actorDecl = decl.as(ActorDeclSyntax.self) {
            group = actorDecl
            attributes = actorDecl.attributes
        } else {
            group = nil
            attributes = []
        }
        guard let group, let node = attributes.first?.as(AttributeSyntax.self) else {
            throw MacroError.invalidType
        }
        return (node, group)
    }

    func expandMembers(
        of node: AttributeSyntax,
        attachedTo declaration: any DeclGroupSyntax,
        in context: BasicMacroExpansionContext
    ) throws -> [DeclSyntax] {
        try EntityMacro.expansion(of: node, providingMembersOf: declaration, in: context)
    }
}
