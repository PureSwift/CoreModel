//
//  CodingKey.swift
//  CoreModel
//
//  Drop-in replacement for `Swift.CodingKey` under Embedded Swift, where the
//  stdlib's Codable machinery (including `CodingKey`) is unavailable.
//

#if hasFeature(Embedded)

/// A type that can be used as a key for encoding and decoding `CoreModel` entities.
///
/// - Note: Under Embedded Swift, `enum CodingKeys: CodingKey { ... }` without an
///   explicit `String` (or `Int`) raw type cannot compile — stdlib `CodingKey`
///   synthesis is compiler magic tied to `Swift.CodingKey`. Declare
///   `enum CodingKeys: String, CodingKey` instead.
public protocol CodingKey: Sendable, CustomStringConvertible, CustomDebugStringConvertible {

    var stringValue: String { get }

    init?(stringValue: String)

    var intValue: Int? { get }

    init?(intValue: Int)
}

extension CodingKey {

    public var description: String { stringValue }

    public var debugDescription: String { stringValue }

    public var intValue: Int? { nil }

    public init?(intValue: Int) { nil }
}

extension CodingKey where Self: RawRepresentable, Self.RawValue == String {

    public var stringValue: String { rawValue }

    public init?(stringValue: String) {
        self.init(rawValue: stringValue)
    }
}

extension CodingKey where Self: RawRepresentable, Self.RawValue == Int {

    public var stringValue: String { rawValue.description }

    public var intValue: Int? { rawValue }

    public init?(stringValue: String) { nil }

    public init?(intValue: Int) {
        self.init(rawValue: intValue)
    }
}

#endif
