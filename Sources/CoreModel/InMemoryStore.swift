//
//  InMemoryStore.swift
//  CoreDataModel
//
//  Created by Alsey Coleman Miller on 11/4/18.
//

import Foundation
import Predicate

/// CoreModel InMemory Store
public final class InMemoryStore: StoreProtocol {
    
    public let model: Model
    
    private var managedObjects = [Identifier: Cache]()
    
    public init(model: Model) {
        
        self.model = model
    }
    
    /// Fetch managed objects.
    public func fetch(_ fetchRequest: FetchRequest) throws -> [ManagedObject] {
        
        
    }
    
    /// Create new managed object.
    public func create(_ entity: String) throws -> ManagedObject {
        
        
    }
    
    /// Delete the specified managed object.
    public func delete(_ managedObject: ManagedObject) {
        
        // remove and release object
        managedObjects[managedObject.identifier] = nil
    }
    
    /// Flush the store's pending changes to the underlying storage format.
    public func save() throws {
        
        // does nothing
    }
    
    // MARK: - Private Methods
    
    fileprivate subscript (identifier: Identifier) -> ManagedObject {
        
        guard let cache = managedObjects[identifier]
            else { fatalError("Invalid identifier") }
        
        return ManagedObject(store: <#T##InMemoryStore#>)
    }
}

// MARK: - ManagedObject

public extension InMemoryStore {
    
    public struct Identifier: RawRepresentable, Equatable, Hashable {
        
        public let rawValue: UUID
        
        public init(rawValue: UUID = UUID()) {
            self.rawValue = rawValue
        }
    }
    
    public final class ManagedObject: CoreModel.ManagedObject {
        
        public private(set) weak var store: InMemoryStore?
        
        public let identifier: Identifier
        
        internal init(identifier: Identifier, store: InMemoryStore) {
            
            self.identifier = identifier
            self.store = store
        }
        
        public func attribute(for key: String) -> AttributeValue {
            
            return attributes[key] ?? .null
        }
        
        public func setAttribute(_ newValue: AttributeValue, for key: String) {
            
            attributes[key] = newValue
        }
        
        public func relationship(for key: String) -> RelationshipValue<ManagedObject> {
            
            guard let relationshipValue = relationships[key]
                else { return .null }
            
            fatalError()
        }
        
        public func setRelationship(_ newValue: RelationshipValue<ManagedObject>, for key: String) {
            
            guard let store = self.store
                else { fatalError("Store released") }
            
            let oldValue = relationships[key] ?? .null
            
            switch newValue {
                
            case .null:
                
                // also clear inverse relationship
                switch oldValue {
                case .null:
                    break // already null
                case let .toOne(identifier):
                    store.managedObjects.
                case let .toMany(identifier):
                    
                }
                
                // set new valuye
                relationships[key] = .null
                
            case let .toOne(managedObject):
                
                
                
            case let .toMany(managedObjects):
                
                
            }
        }
        
        public var hashValue: Int {
            
            return identifier.hashValue
        }
        
        public static func == (lhs: ManagedObject, rhs: ManagedObject) -> Bool {
            
            return lhs.identifier == rhs.identifier
        }
    }
}

private extension InMemoryStore {
    
    struct Cache {
        
        var attributes = [String: AttributeValue]()
        var relationships = [String: Relationship]()
    }
    
    enum Relationship {
        
        case null
        case toOne(Identifier)
        case toMany(Set<Identifier>)
    }
}


