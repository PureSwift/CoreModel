//
//  Store.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/22/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

/// CoreModel Store Protocol
public protocol ModelStorage: AnyObject {
    
    /// Fetch managed object.
    func fetch(_ entity: EntityName, for id: ObjectID) async throws -> ModelData?
    
    /// Fetch managed objects.
    func fetch(_ fetchRequest: FetchRequest) async throws -> [ModelData]
    
    /// Fetch and return result count.
    func count(_ fetchRequest: FetchRequest) async throws -> UInt
    
    /// Create or edit a managed object.
    func insert(_ value: ModelData) async throws
    
    /// Delete the specified managed object. 
    func delete(_ entity: EntityName, for id: ObjectID) async throws
}

public extension ModelStorage {
    
    func count(_ fetchRequest: FetchRequest) async throws -> UInt {
        return try await UInt(fetch(fetchRequest).count)
    }
}

/// CoreModel Object Instance
public struct ModelData: Equatable, Hashable, Identifiable, Codable {
    
    public let entity: EntityName
    
    public let id: ObjectID
    
    public var attributes: [PropertyKey: AttributeValue]
    
    public var relationships: [PropertyKey: RelationshipValue]
    
    public init(
        entity: EntityName,
        id: ObjectID,
        attributes: [PropertyKey : AttributeValue] = [:],
        relationships: [PropertyKey : RelationshipValue] = [:]
    ) {
        self.entity = entity
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }
}
