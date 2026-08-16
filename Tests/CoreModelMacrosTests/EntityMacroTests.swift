//
//  EntityMacroTests.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/17/25.
//

// Macro expansion tests depend on the swift-syntax host tooling and only run
// where the test suite is executed (macOS and Linux); other CI platforms
// cross-compile the package and never run `swift test`.
#if os(macOS) || os(Linux)

import Foundation
import Testing
import SwiftSyntax
import SwiftParser
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion
@testable import CoreModelMacros

@Suite struct EntityMacroTests {

    @Test func structExpansion() throws {
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
        #expect(members.count == 5)
        let source = members.map { $0.description }.joined(separator: "\n")
        #expect(source.contains(#"public static var entityName: EntityName { "Person" }"#))
        #expect(source.contains(".name: .string"))
        #expect(source.contains(".age: .int64"))
        #expect(source.contains(".created: .date"))
        #expect(source.contains("public static var relationships: [CodingKeys: Relationship] { [:] }"))
        #expect(source.contains("public init(from container: ModelData) throws"))
        #expect(source.contains("self.name = try container.decode(String.self, forKey: Person.CodingKeys.name)"))
        #expect(source.contains("public func encode() -> ModelData"))
        #expect(source.contains("container.encode(self.age, forKey: Person.CodingKeys.age)"))
    }

    @Test func extensionExpansion() throws {
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
        #expect(extensions.count == 1)
        #expect(extensions[0].description.contains("CoreModel.Entity"))
    }

    @Test func explicitEntityName() throws {
        let (node, declaration) = try parse("""
        @Entity("PersonEntity")
        struct Person {
            var id: UUID
        }
        """)
        let context = BasicMacroExpansionContext()
        let decl = try EntityMacro.entityNameDeclarationSyntax(of: node, providingMembersOf: declaration, in: context)
        #expect(decl.description.contains(#""PersonEntity""#))
    }

    @Test func optionalAttributes() throws {
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
        #expect(decl.description.contains(".nickname: .string"))
        #expect(decl.description.contains(".count: .int64"))
    }

    @Test func explicitAttributeType() throws {
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
        #expect(decl.description.contains(".avatar: .data"))
    }

    @Test func unknownAttributeType() throws {
        let (node, declaration) = try parse("""
        @Entity
        struct Person {
            var id: UUID
            @Attribute
            var point: CGPoint
        }
        """)
        let context = BasicMacroExpansionContext()
        do {
            _ = try EntityMacro.attributesDeclarationSyntax(of: node, providingMembersOf: declaration, in: context)
            Issue.record("Expected an error")
        } catch MacroError.unknownAttributeType(let name) {
            #expect(name == "point")
        } catch {
            Issue.record("Expected unknownAttributeType, got \(error)")
        }
    }

    @Test func relationships() throws {
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
        #expect(source.contains("destination: Pet.self"))
        #expect(source.contains("type: .toMany"))
        #expect(source.contains("inverseRelationship: .owner"))
        #expect(source.contains("destination: Company.self"))
        #expect(source.contains("type: .toOne"))
        #expect(source.contains("inverseRelationship: .employees"))
    }

    @Test func missingInverseRelationship() throws {
        let (node, declaration) = try parse("""
        @Entity
        struct Person {
            var id: UUID
            @Relationship
            var pets: [Pet.ID]
        }
        """)
        let context = BasicMacroExpansionContext()
        do {
            _ = try EntityMacro.relationshipsDeclarationSyntax(of: node, providingMembersOf: declaration, in: context)
            Issue.record("Expected an error")
        } catch MacroError.unknownInverseRelationship(let name) {
            #expect(name == "pets")
        } catch {
            Issue.record("Expected unknownInverseRelationship, got \(error)")
        }
    }

    @Test func invalidInverseExpression() throws {
        let (node, declaration) = try parse("""
        @Entity
        struct Person {
            var id: UUID
            @Relationship(inverse: "owner")
            var pets: [Pet.ID]
        }
        """)
        let context = BasicMacroExpansionContext()
        do {
            _ = try EntityMacro.relationshipsDeclarationSyntax(of: node, providingMembersOf: declaration, in: context)
            Issue.record("Expected an error")
        } catch MacroError.unknownInverseRelationship {
            // expected
        } catch {
            Issue.record("Expected unknownInverseRelationship, got \(error)")
        }
    }

    @Test func relationshipDecodeEncode() throws {
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
        #expect(initDecl.description.contains("self.pets = try container.decodeRelationship([Pet.ID].self, forKey: Person.CodingKeys.pets)"))
        let encodeDecl = try EntityMacro.encodeDeclarationSyntax(of: node, providingMembersOf: declaration, in: context)
        #expect(encodeDecl.description.contains("container.encodeRelationship(self.pets, forKey: Person.CodingKeys.pets)"))
    }

    @Test func unrelatedPropertyAttributeIgnored() throws {
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
        #expect(properties.map { $0.name } == ["name"])
        let initDecl = try EntityMacro.initDeclarationSyntax(of: node, providingMembersOf: declaration, in: context)
        #expect(initDecl.description.contains("ignored") == false)
    }

    @Test func classTypeName() throws {
        let (node, declaration) = try parse("""
        @Entity
        class Animal {
            var id: UUID = UUID()
        }
        """)
        let context = BasicMacroExpansionContext()
        #expect(try EntityMacro.typeName(of: node, providingMembersOf: declaration, in: context) == "Animal")
    }

    @Test func enumTypeName() throws {
        let (node, declaration) = try parse("""
        @Entity
        enum Kind {
            case dog
        }
        """)
        let context = BasicMacroExpansionContext()
        #expect(try EntityMacro.typeName(of: node, providingMembersOf: declaration, in: context) == "Kind")
    }

    @Test func invalidType() throws {
        let (node, declaration) = try parse("""
        @Entity
        actor Worker {
            var id: UUID = UUID()
        }
        """)
        let context = BasicMacroExpansionContext()
        do {
            _ = try EntityMacro.typeName(of: node, providingMembersOf: declaration, in: context)
            Issue.record("Expected an error")
        } catch MacroError.invalidType {
            // expected
        } catch {
            Issue.record("Expected invalidType, got \(error)")
        }
    }

    @Test func inferAttributeTypeMapping() {
        #expect(inferAttributeType(from: "String") == ".string")
        #expect(inferAttributeType(from: "Data") == ".data")
        #expect(inferAttributeType(from: "Bool") == ".bool")
        #expect(inferAttributeType(from: "Int16") == ".int16")
        #expect(inferAttributeType(from: "Int32") == ".int32")
        #expect(inferAttributeType(from: "Int64") == ".int64")
        #expect(inferAttributeType(from: "Int") == ".int64")
        #expect(inferAttributeType(from: "Float") == ".float")
        #expect(inferAttributeType(from: "Double") == ".double")
        #expect(inferAttributeType(from: "Date") == ".date")
        #expect(inferAttributeType(from: "UUID") == ".uuid")
        #expect(inferAttributeType(from: "URL") == ".url")
        #expect(inferAttributeType(from: "Decimal") == ".decimal")
        #expect(inferAttributeType(from: "CGPoint") == nil)
    }

    @Test func peerMacrosExpandToNothing() throws {
        let (node, declaration) = try parse("""
        @Entity
        struct Person {
            var id: UUID
        }
        """)
        let context = BasicMacroExpansionContext()
        #expect(try AttributeMacro.expansion(of: node, providingPeersOf: declaration, in: context).count == 0)
        #expect(try RelationshipMacro.expansion(of: node, providingPeersOf: declaration, in: context).count == 0)
        #expect(try CompositeAttributeMacro.expansion(of: node, providingPeersOf: declaration, in: context).count == 0)
    }

    @Test func expansionNames() {
        #expect(EntityMacro.expansionNames.count == 5)
    }

    // MARK: - Composite Attributes

    @Test func compositeAttribute() throws {
        let (node, declaration) = try parse("""
        @Entity
        struct Campground {
            var id: UUID
            @CompositeAttribute
            var location: LocationCoordinates
        }
        """)
        let context = BasicMacroExpansionContext()
        let source = try expandMembers(of: node, attachedTo: declaration, in: context)
            .map { $0.description }.joined(separator: "\n")
        #expect(source.contains(".location: LocationCoordinates.attributeType"))
        // encode/decode codegen is unchanged
        #expect(source.contains("container.decode(LocationCoordinates.self, forKey: Campground.CodingKeys.location)"))
        #expect(source.contains("container.encode(self.location, forKey: Campground.CodingKeys.location)"))
    }

    @Test func optionalCompositeAttribute() throws {
        for declared in ["LocationCoordinates?", "Optional<LocationCoordinates>"] {
            let (node, declaration) = try parse("""
            @Entity
            struct Campground {
                var id: UUID
                @CompositeAttribute
                var location: \(declared)
            }
            """)
            let context = BasicMacroExpansionContext()
            let source = try expandMembers(of: node, attachedTo: declaration, in: context)
                .map { $0.description }.joined(separator: "\n")
            // the Optional wrapper is stripped for the element list ...
            #expect(source.contains(".location: LocationCoordinates.attributeType"))
            // ... but kept for decoding, which routes through the Optional conformance
            #expect(source.contains("container.decode(\(declared).self, forKey: Campground.CodingKeys.location)"))
        }
    }

    @Test func nestedCompositeTypeName() throws {
        let (node, declaration) = try parse("""
        @Entity
        struct Campground {
            var id: UUID
            @CompositeAttribute
            var location: Campground.LocationCoordinates
        }
        """)
        let context = BasicMacroExpansionContext()
        let source = try expandMembers(of: node, attachedTo: declaration, in: context)
            .map { $0.description }.joined(separator: "\n")
        #expect(source.contains(".location: Campground.LocationCoordinates.attributeType"))
    }

    /// `@Attribute` with an explicit composite type works with no macro support,
    /// since the argument is passed through verbatim.
    @Test func explicitCompositeAttributeType() throws {
        let (node, declaration) = try parse("""
        @Entity
        struct Campground {
            var id: UUID
            @Attribute(LocationCoordinates.attributeType)
            var location: LocationCoordinates
        }
        """)
        let context = BasicMacroExpansionContext()
        let source = try expandMembers(of: node, attachedTo: declaration, in: context)
            .map { $0.description }.joined(separator: "\n")
        #expect(source.contains(".location: LocationCoordinates.attributeType"))
    }

    @Test func invalidCompositeAttribute() throws {
        // a collection type cannot be a composite
        let (node, declaration) = try parse("""
        @Entity
        struct Campground {
            var id: UUID
            @CompositeAttribute
            var tags: [Tag]
        }
        """)
        let context = BasicMacroExpansionContext()
        #expect(throws: MacroError.self) {
            try expandMembers(of: node, attachedTo: declaration, in: context)
        }
        // arguments are not accepted
        let (node2, declaration2) = try parse("""
        @Entity
        struct Campground {
            var id: UUID
            @CompositeAttribute(.string)
            var location: LocationCoordinates
        }
        """)
        #expect(throws: MacroError.self) {
            try expandMembers(of: node2, attachedTo: declaration2, in: BasicMacroExpansionContext())
        }
    }

    @Test func compositeCodableProperties() throws {
        let (_, declaration) = try parse("""
        @Entity
        struct Campground {
            var id: UUID
            @CompositeAttribute
            var location: LocationCoordinates
        }
        """)
        let properties = EntityMacro.codableProperties(of: declaration)
        #expect(properties.count == 1)
        #expect(properties[0].name == "location")
        #expect(properties[0].isRelationship == false)
    }

    /// An entity mixing scalar attributes, required and optional composites, and a
    /// relationship generates all five members consistently.
    @Test func mixedEntityExpansion() throws {
        let (node, declaration) = try parse("""
        @Entity("Campground")
        struct Campground {
            var id: UUID
            @Attribute
            var name: String
            @CompositeAttribute
            var location: LocationCoordinates
            @CompositeAttribute
            var officeHours: Schedule?
            @Relationship(destination: Unit.self, inverse: .campground)
            var units: [Unit.ID]
        }
        """)
        let context = BasicMacroExpansionContext()
        let members = try expandMembers(of: node, attachedTo: declaration, in: context)
        #expect(members.count == 5)
        let source = members.map { $0.description }.joined(separator: "\n")
        #expect(source.contains(#"public static var entityName: EntityName { "Campground" }"#))
        // scalar and composite attributes live side by side
        #expect(source.contains(".name: .string"))
        #expect(source.contains(".location: LocationCoordinates.attributeType"))
        #expect(source.contains(".officeHours: Schedule.attributeType"))
        // the relationship is not folded into `attributes`
        #expect(source.contains(".units: .string") == false)
        #expect(source.contains(".units: Unit.attributeType") == false)
        #expect(source.contains(".units: Relationship("))
        #expect(source.contains("destination: Unit.self"))
        // decode keeps the optional wrapper, encode passes the property through
        #expect(source.contains("container.decode(LocationCoordinates.self, forKey: Campground.CodingKeys.location)"))
        #expect(source.contains("container.decode(Schedule?.self, forKey: Campground.CodingKeys.officeHours)"))
        #expect(source.contains("container.encode(self.location, forKey: Campground.CodingKeys.location)"))
        #expect(source.contains("container.encodeRelationship(self.units, forKey: Campground.CodingKeys.units)"))
    }

    @Test func multipleCompositeAttributes() throws {
        let (node, declaration) = try parse("""
        @Entity
        struct Campground {
            var id: UUID
            @CompositeAttribute
            var location: LocationCoordinates
            @CompositeAttribute
            var officeHours: Schedule
        }
        """)
        let context = BasicMacroExpansionContext()
        let source = try expandMembers(of: node, attachedTo: declaration, in: context)
            .map { $0.description }.joined(separator: "\n")
        #expect(source.contains(".location: LocationCoordinates.attributeType"))
        #expect(source.contains(".officeHours: Schedule.attributeType"))
        // declaration order is preserved
        let properties = EntityMacro.codableProperties(of: declaration)
        #expect(properties.map { $0.name } == ["location", "officeHours"])
    }

    @Test func compositeAttributeInClass() throws {
        let (node, declaration) = try parse("""
        @Entity
        class Campground {
            var id: UUID
            @CompositeAttribute
            var location: LocationCoordinates
        }
        """)
        let context = BasicMacroExpansionContext()
        let source = try expandMembers(of: node, attachedTo: declaration, in: context)
            .map { $0.description }.joined(separator: "\n")
        #expect(source.contains(".location: LocationCoordinates.attributeType"))
    }

    @Test func compositeExtensionExpansion() throws {
        let (node, declaration) = try parse("""
        @Entity
        struct Campground {
            var id: UUID
            @CompositeAttribute
            var location: LocationCoordinates
        }
        """)
        let context = BasicMacroExpansionContext()
        let extensions = try EntityMacro.expansion(
            of: node,
            attachedTo: declaration,
            providingExtensionsOf: TypeSyntax(stringLiteral: "Campground"),
            conformingTo: [],
            in: context
        )
        #expect(extensions.count == 1)
        #expect(extensions[0].description.contains("CoreModel.Entity"))
    }

    /// A property with no type annotation carries no type name to build elements from,
    /// so it is skipped rather than crashing.
    @Test func compositeAttributeWithoutTypeAnnotation() throws {
        let (node, declaration) = try parse("""
        @Entity
        struct Campground {
            var id: UUID
            @CompositeAttribute
            var location = LocationCoordinates(latitude: 0, longitude: 0)
        }
        """)
        let context = BasicMacroExpansionContext()
        let source = try expandMembers(of: node, attachedTo: declaration, in: context)
            .map { $0.description }.joined(separator: "\n")
        #expect(source.contains("location") == false)
        #expect(EntityMacro.codableProperties(of: declaration).isEmpty)
    }

    @Test func compositeAttributeRejectsCollections() throws {
        for declared in ["[LocationCoordinates]", "[String: LocationCoordinates]"] {
            let (node, declaration) = try parse("""
            @Entity
            struct Campground {
                var id: UUID
                @CompositeAttribute
                var values: \(declared)
            }
            """)
            #expect(throws: MacroError.self) {
                try expandMembers(of: node, attachedTo: declaration, in: BasicMacroExpansionContext())
            }
        }
    }

    /// `@Attribute` and `@CompositeAttribute` are the only attribute spellings that
    /// contribute; an unrelated property wrapper is still ignored.
    @Test func unrelatedAttributeIgnoredAlongsideComposite() throws {
        let (node, declaration) = try parse("""
        @Entity
        struct Campground {
            var id: UUID
            @CompositeAttribute
            var location: LocationCoordinates
            @Published
            var ignored: Int
        }
        """)
        let context = BasicMacroExpansionContext()
        let properties = EntityMacro.codableProperties(of: declaration)
        #expect(properties.map { $0.name } == ["location"])
        let initDecl = try EntityMacro.initDeclarationSyntax(of: node, providingMembersOf: declaration, in: context)
        #expect(initDecl.description.contains("ignored") == false)
    }

    #if canImport(Darwin)
    @Test func macroErrorDescriptions() {
        #expect(MacroError.invalidType.errorDescription != nil)
        #expect(MacroError.unknownAttributeType(for: "point").errorDescription != nil)
        #expect(MacroError.unknownInverseRelationship(for: "pets").errorDescription != nil)
        #expect(MacroError.invalidCompositeAttribute(for: "location").errorDescription != nil)
    }
    #endif
}

// MARK: - Helpers

extension EntityMacroTests {

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

#endif
