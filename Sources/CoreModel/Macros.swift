//
//  Macros.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/17/25.
//

#if !hasFeature(Embedded) && SWIFTPM_ENABLE_MACROS
@attached(member, names: arbitrary)
@attached(extension, conformances: CoreModel.Entity)
public macro Entity(_ name: String? = nil) = #externalMacro(
    module: "CoreModelMacros",
    type: "EntityMacro"
)

@attached(peer)
public macro Attribute(_ type: AttributeType? = nil) = #externalMacro(
    module: "CoreModelMacros",
    type: "AttributeMacro"
)

@attached(peer)
public macro Relationship<T: CoreModel.Entity>(destination: T.Type, inverse: T.CodingKeys) = #externalMacro(
    module: "CoreModelMacros",
    type: "RelationshipMacro"
)
#endif
