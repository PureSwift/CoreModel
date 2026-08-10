//
//  InMemoryStore.swift
//  CoreModel
//
//  Created by Alsey Coleman Miller on 7/21/26.
//  Copyright © 2026 PureSwift. All rights reserved.
//

#if canImport(Darwin)
import Foundation
#endif
import Synchronization

/// Mutable state behind a lock.
///
/// The capability protocols are `Sendable`, so the mocks that implement them have to
/// be too — but a recording mock is mutable by definition. This is the smallest thing
/// that reconciles the two without pulling in a dependency.
///
/// Backed by `Mutex` wherever the runtime has it (non-Darwin, and Darwin at or above
/// iOS 18 / macOS 15), falling back to `NSLock` on the older Darwin releases this
/// package still deploys to.
internal final class Locked<Value>: Sendable {

    // `@available` isn't allowed on enum cases with associated values, and naming the
    // Mutex-backed class in a payload would require it — so that payload is stored
    // erased and downcast behind the same availability check that constructed it.
    private enum Storage: @unchecked Sendable {
        case mutex(AnyObject)
        #if canImport(Darwin)
        case nsLock(NSLockStorage<Value>)
        #endif
    }

    private let storage: Storage

    public init(_ value: Value) {
        #if canImport(Darwin)
        if #available(iOS 18, macOS 15, watchOS 11, tvOS 18, visionOS 2, *) {
            self.storage = .mutex(MutexStorage(value))
        } else {
            self.storage = .nsLock(NSLockStorage(value))
        }
        #else
        self.storage = .mutex(MutexStorage(value))
        #endif
    }

    public var value: Value {
        withValue { $0 }
    }

    @discardableResult
    public func withValue<Result, Failure: Error>(
        _ body: (inout Value) throws(Failure) -> Result
    ) throws(Failure) -> Result {
        switch storage {
        case .mutex(let storage):
            guard #available(iOS 18, macOS 15, watchOS 11, tvOS 18, visionOS 2, *) else {
                fatalError("Mutex storage constructed on an OS without the Synchronization runtime")
            }
            return try unsafeDowncast(storage, to: MutexStorage<Value>.self).withValue(body)
        #if canImport(Darwin)
        case .nsLock(let storage):
            return try storage.withValue(body)
        #endif
        }
    }
}

// MARK: - Storage

@available(iOS 18, macOS 15, watchOS 11, tvOS 18, visionOS 2, *)
private final class MutexStorage<Value>: Sendable {

    // `Mutex` requires `sending` values in and out; `Locked` predates that and promises
    // only what `NSLock` did. The wrapper opts out of the transfer checking so both
    // backends expose identical semantics.
    private struct UncheckedSendable<Wrapped>: @unchecked Sendable {
        var wrapped: Wrapped
    }

    private let mutex: Mutex<UncheckedSendable<Value>>

    init(_ value: Value) {
        self.mutex = Mutex(UncheckedSendable(wrapped: value))
    }

    func withValue<Result, Failure: Error>(
        _ body: (inout Value) throws(Failure) -> Result
    ) throws(Failure) -> Result {
        try mutex.withLock { (state: inout UncheckedSendable<Value>) throws(Failure) -> UncheckedSendable<Result> in
            UncheckedSendable(wrapped: try body(&state.wrapped))
        }.wrapped
    }
}

#if canImport(Darwin)
private final class NSLockStorage<Value>: @unchecked Sendable {

    private let lock = NSLock()

    private var value: Value

    init(_ value: Value) {
        self.value = value
    }

    func withValue<Result, Failure: Error>(
        _ body: (inout Value) throws(Failure) -> Result
    ) throws(Failure) -> Result {
        lock.lock()
        defer { lock.unlock() }
        return try body(&value)
    }
}
#endif
