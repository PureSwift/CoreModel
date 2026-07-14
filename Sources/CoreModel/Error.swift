//
//  Error.swift
//  
//
//  Created by Alsey Coleman Miller on 8/16/23.
//

/// CoreModel Error
public enum CoreModelError: Error {

    /// Invalid or unknown entity
    case invalidEntity(EntityName)

    #if hasFeature(Embedded)
    /// Decoding failures under Embedded Swift (`Swift.DecodingError` is unavailable).
    case keyNotFound(PropertyKey)
    case typeMismatch(PropertyKey)
    case invalidIdentifier(ObjectID)
    #endif
}

// MARK: - Decoding Error Factories

#if hasFeature(Embedded)

// - Note: Embedded Swift disallows `any Error` as a value/return type (existential
//   restriction), so these return the concrete `CoreModelError` instead of `any Error`.

internal func coreModelKeyNotFoundError<K: CodingKey>(_ key: K) -> CoreModelError {
    CoreModelError.keyNotFound(PropertyKey(key))
}

internal func coreModelTypeMismatchError<T, K: CodingKey>(_ type: T.Type, forKey key: K, from value: Any) -> CoreModelError {
    CoreModelError.typeMismatch(PropertyKey(key))
}

internal func coreModelInvalidIdentifierError(_ objectID: ObjectID) -> CoreModelError {
    CoreModelError.invalidIdentifier(objectID)
}

#else

internal func coreModelKeyNotFoundError<K: CodingKey>(_ key: K) -> any Error {
    DecodingError.keyNotFound(key, DecodingError.Context(codingPath: [], debugDescription: "Key \(key.stringValue) not found"))
}

internal func coreModelTypeMismatchError<T, K: CodingKey>(_ type: T.Type, forKey key: K, from value: Any) -> any Error {
    DecodingError.typeMismatch(type, DecodingError.Context(codingPath: [], debugDescription: "Cannot decode \(String(describing: type)) from \(value)"))
}

internal func coreModelInvalidIdentifierError(_ objectID: ObjectID) -> any Error {
    DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Cannot decode identifier from \(objectID)"))
}

#endif
