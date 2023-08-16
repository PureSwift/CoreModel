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
    
    private var data = [Identifier: Cache]()
    
    public init(model: Model) {
        self.model = model
    }
    
    /// Fetch managed objects.
    public func fetch(_ fetchRequest: FetchRequest) throws -> [ManagedObject] {
        
        var identifiers = data.keys.filter { $0.entity == fetchRequest.entity }
        
        if fetchRequest.fetchOffset > 0 {
            identifiers = Array(identifiers.suffix(fetchRequest.fetchOffset))
        }
        
        if fetchRequest.fetchLimit > 0 {
            identifiers = Array(identifiers.prefix(fetchRequest.fetchLimit))
        }
        
        var managedObjects = identifiers.map { ManagedObject(identifier: $0, store: self) }
        
        if let predicate = fetchRequest.predicate {
            
            managedObjects = try managedObjects.filter {
                try $0.evaluate(with: predicate)
            }
        }
        
        if fetchRequest.sortDescriptors.isEmpty == false {
            
            for sort in fetchRequest.sortDescriptors.reversed() {
                
                //managedObjects.sort(by: { $0. })
            }
        }
        
        return managedObjects
    }
    
    /// Create new managed object.
    public func create(_ entity: String) throws -> ManagedObject {
        
        let identifier = Identifier(entity: entity, uuid: UUID())
        
        self.data[identifier] = Cache(attributes: [:],
                                      relationships: [:])
        
        return ManagedObject(identifier: identifier, store: self)
    }
    
    /// Delete the specified managed object.
    public func delete(_ managedObject: ManagedObject) {
        
        let entityName = managedObject.identifier.entity
        
        guard let entity = model[entityName]
            else { fatalError() }
        
        for relationship in entity.relationships {
            
            managedObject.setRelationship(.null, for: relationship.name)
        }
        
        // remove and release object
        data[managedObject.identifier] = nil
    }
    
    /// Flush the store's pending changes to the underlying storage format.
    public func save() throws {
        
        // does nothing
    }
}

// MARK: - ManagedObject

public extension InMemoryStore {
    
    struct Identifier: Equatable, Hashable {
        
        public let entity: String
        
        public let uuid: UUID
    }
    
    final class ManagedObject: CoreModel.ManagedObject {
        
        public private(set) weak var store: InMemoryStore?
        
        public let identifier: Identifier
        
        internal init(identifier: Identifier, store: InMemoryStore) {
            
            self.identifier = identifier
            self.store = store
        }
        
        public var isDeleted: Bool {
            
            guard let store = self.store
                else { fatalError() }
            
            return store.data[identifier] == nil
        }
        
        public func attribute(for key: String) -> AttributeValue {
            
            guard let store = self.store
                else { fatalError() }
            
            return store.data[identifier]?.attributes[key] ?? .null
        }
        
        public func setAttribute(_ newValue: AttributeValue, for key: String) {
            
            guard let store = self.store
                else { fatalError() }
            
            store.data[identifier]?.attributes[key] = newValue
        }
        
        public func relationship(for key: String) -> RelationshipValue<ManagedObject> {
            
            guard let store = self.store
                else { fatalError() }
            
            guard let relationshipValue = store.data[identifier]?.relationships[key]
                else { return .null }
            
            switch relationshipValue {
            case .null:
                return .null
            case let .toOne(identifier):
                return .toOne(ManagedObject(identifier: identifier, store: store))
            case let .toMany(identifiers):
                return .toMany(Set(identifiers.map { ManagedObject(identifier: $0, store: store) }))
            }
        }
        
        public func setRelationship(_ newValue: RelationshipValue<ManagedObject>,
                                    for key: String) {
            
            setRelationship(newValue, for: key, applyInverse: true)
        }
        
        private func clearInverseRelationship(for key: String, inverse: ManagedObject) {
            
            let relationshipValue = self.relationship(for: key)
            switch relationshipValue {
            case .null:
                break
            case .toOne:
                setRelationship(.null,
                                for: key,
                                applyInverse: false)
            case let .toMany(inverseManagedObjects):
                var newValue = inverseManagedObjects
                newValue.remove(inverse)
                setRelationship(.toMany(newValue),
                                for: key,
                                applyInverse: false)
            }
        }
                
        private func setRelationship(_ newValue: RelationshipValue<ManagedObject>,
                                    for key: String,
                                    applyInverse: Bool) {
            
            guard let store = self.store
                else { fatalError() }
            
            guard let entity = store.model[identifier.entity],
                let relationshipDescription = entity[relationship: key],
                let inverseEntity = store.model[relationshipDescription.destinationEntity],
                let inverseRelationship = inverseEntity[relationship: relationshipDescription.inverseRelationship]
                else { fatalError() }
            
            let oldValue = self.relationship(for: key)
            
            // clear inverse relationship
            if applyInverse {
                
                switch oldValue {
                case .null:
                    break // already null
                case let .toOne(managedObject):
                    managedObject.clearInverseRelationship(for: inverseRelationship.name,
                                                           inverse: self)
                case let .toMany(managedObjects):
                    for managedObject in managedObjects {
                        managedObject.clearInverseRelationship(for: inverseRelationship.name,
                                                               inverse: self)
                    }
                }
            }
            
            let newRelationship: Relationship
            
            switch newValue {
            case .null:
                newRelationship = .null
            case let .toOne(managedObject):
                newRelationship = .toOne(managedObject.identifier)
                if applyInverse {
                    switch inverseRelationship.type {
                    case .toOne:
                        managedObject.setRelationship(.toOne(self),
                                                      for: inverseRelationship.name,
                                                      applyInverse: false)
                    case .toMany:
                        var newSet: Set<ManagedObject>
                        let currentValue = managedObject.relationship(for: inverseRelationship.name)
                        switch currentValue {
                        case .null:
                            newSet = []
                        case let .toMany(oldSet):
                            newSet = oldSet
                        case .toOne:
                            fatalError("Invalid")
                        }
                        newSet.insert(self)
                        managedObject.setRelationship(.toMany(newSet),
                                                      for: inverseRelationship.name,
                                                      applyInverse: false)
                    }
                }
            case let .toMany(managedObjects):
                newRelationship = .toMany(Set(managedObjects.map { $0.identifier }))
                if applyInverse {
                    for managedObject in managedObjects {
                        switch inverseRelationship.type {
                        case .toOne:
                            managedObject.setRelationship(.toOne(self),
                                                          for: inverseRelationship.name,
                                                          applyInverse: false)
                        case .toMany:
                            var newSet: Set<ManagedObject>
                            let currentValue = managedObject.relationship(for: inverseRelationship.name)
                            switch currentValue {
                            case .null:
                                newSet = []
                            case let .toMany(oldSet):
                                newSet = oldSet
                            case .toOne:
                                fatalError("Invalid")
                            }
                            newSet.insert(self)
                            managedObject.setRelationship(.toMany(newSet),
                                                          for: inverseRelationship.name,
                                                          applyInverse: false)
                        }
                    }
                }
            }
            
            store.data[identifier]?.relationships[key] = newRelationship
            
            // set inverse
            
        }
        
        public func hash(into hasher: inout Hasher) {
            identifier.hash(into: &hasher)
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

extension InMemoryStore.ManagedObject: PredicateEvaluatable {
    
    public func evaluate(with predicate: Predicate) throws -> Bool {
        false
    }
}
