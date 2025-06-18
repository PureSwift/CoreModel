//
//  Macros.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 6/17/25.
//



@attached(member, names: named(entityName))
public macro Entity(_ name: String? = nil) = #externalMacro(
    module: "CoreModelMacros",
    type: "EntityMacro"
)

@attached(peer)
public macro Attribute(type: AttributeType? = nil) = #externalMacro(
    module: "CoreModelMacros",
    type: "AttributeMacro"
)

@attached(peer)
public macro Relationship<K: CodingKey>(inverse: CodingKey) = #externalMacro(
    module: "CoreModelMacros",
    type: "RelationshipMacro"
)
