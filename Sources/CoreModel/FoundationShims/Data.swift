//
//  Data.swift
//  CoreModel
//
//  Minimal Foundation-free `Data` for platforms without Foundation
//  (e.g. Embedded Swift). Not API-complete — storage-layer round-tripping only.
//

#if !canImport(FoundationEssentials) && !canImport(Foundation)

public struct Data: Sendable {

    internal var bytes: [UInt8]

    public init() {
        self.bytes = []
    }

    public init<S: Sequence>(_ elements: S) where S.Element == UInt8 {
        self.bytes = Array(elements)
    }

    public init(repeating byte: UInt8, count: Int) {
        self.bytes = Array(repeating: byte, count: count)
    }
}

// MARK: - Collection

extension Data: RandomAccessCollection, MutableCollection {

    public typealias Element = UInt8
    public typealias Index = Int

    public var startIndex: Int { bytes.startIndex }
    public var endIndex: Int { bytes.endIndex }

    public subscript(position: Int) -> UInt8 {
        get { bytes[position] }
        set { bytes[position] = newValue }
    }

    public func index(after i: Int) -> Int { bytes.index(after: i) }
    public func index(before i: Int) -> Int { bytes.index(before: i) }
}

extension Data {

    public mutating func append(_ byte: UInt8) {
        bytes.append(byte)
    }

    public mutating func append<S: Sequence>(contentsOf newElements: S) where S.Element == UInt8 {
        bytes.append(contentsOf: newElements)
    }
}

// MARK: - Equatable, Hashable

extension Data: Equatable, Hashable {

    public static func == (lhs: Data, rhs: Data) -> Bool {
        lhs.bytes == rhs.bytes
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(bytes)
    }
}

// MARK: - CustomStringConvertible

extension Data: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        "\(count) bytes"
    }

    public var debugDescription: String {
        description
    }
}

// MARK: - Codable

#if !hasFeature(Embedded)
extension Data: Codable {

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var bytes: [UInt8] = []
        if let count = container.count {
            bytes.reserveCapacity(count)
        }
        while !container.isAtEnd {
            bytes.append(try container.decode(UInt8.self))
        }
        self.init(bytes)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        for byte in bytes {
            try container.encode(byte)
        }
    }
}
#endif

#endif
