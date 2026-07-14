//
//  UUID.swift
//  CoreModel
//
//  Minimal Foundation-free `UUID` for platforms without Foundation
//  (e.g. Embedded Swift). Modeled on PureSwift/Bluetooth's embedded UUID.
//  Not API-complete — storage-layer round-tripping only.
//

#if !canImport(FoundationEssentials) && !canImport(Foundation)

public struct UUID: Sendable {

    public typealias ByteValue = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)

    public let uuid: ByteValue

    public init(uuid: ByteValue) {
        self.uuid = uuid
    }
}

// MARK: - Random Initialization

extension UUID {

    /// Create a new UUID with RFC 4122 version 4 random bytes.
    public init() {
        var uuidBytes: ByteValue = (
            .random(in: 0...255),
            .random(in: 0...255),
            .random(in: 0...255),
            .random(in: 0...255),
            .random(in: 0...255),
            .random(in: 0...255),
            .random(in: 0...255),
            .random(in: 0...255),
            .random(in: 0...255),
            .random(in: 0...255),
            .random(in: 0...255),
            .random(in: 0...255),
            .random(in: 0...255),
            .random(in: 0...255),
            .random(in: 0...255),
            .random(in: 0...255)
        )

        // Set the version to 4 (random UUID)
        uuidBytes.6 = (uuidBytes.6 & 0x0F) | 0x40

        // Set the variant to RFC 4122
        uuidBytes.8 = (uuidBytes.8 & 0x3F) | 0x80

        self.init(uuid: uuidBytes)
    }
}

// MARK: - String Parsing / Formatting

extension UUID {

    /// Create a UUID from a string such as "E621E1F8-C36C-495A-93FC-0C247A3E6E5F".
    ///
    /// Returns nil for invalid strings.
    public init?(uuidString string: String) {
        guard let value = UInt128.bigEndian(uuidString: string) else {
            return nil
        }
        self.init(uuid: value.bytes)
    }

    /// Returns a string created from the UUID, such as "E621E1F8-C36C-495A-93FC-0C247A3E6E5F"
    public var uuidString: String {
        UInt128(bytes: uuid).bigEndianUUIDString
    }
}

// MARK: - Equatable

extension UUID: Equatable {

    public static func == (lhs: UUID, rhs: UUID) -> Bool {
        Swift.withUnsafeBytes(of: lhs.uuid) { lhsPtr in
            Swift.withUnsafeBytes(of: rhs.uuid) { rhsPtr in
                let lhsTuple = lhsPtr.loadUnaligned(as: (UInt64, UInt64).self)
                let rhsTuple = rhsPtr.loadUnaligned(as: (UInt64, UInt64).self)
                return (lhsTuple.0 ^ rhsTuple.0) | (lhsTuple.1 ^ rhsTuple.1) == 0
            }
        }
    }
}

// MARK: - Hashable

extension UUID: Hashable {

    public func hash(into hasher: inout Hasher) {
        Swift.withUnsafeBytes(of: uuid) { buffer in
            hasher.combine(bytes: buffer)
        }
    }
}

// MARK: - CustomStringConvertible

extension UUID: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        uuidString
    }

    public var debugDescription: String {
        description
    }
}

// MARK: - Comparable

extension UUID: Comparable {

    public static func < (lhs: UUID, rhs: UUID) -> Bool {
        var leftUUID = lhs.uuid
        var rightUUID = rhs.uuid
        var result: Int = 0
        var diff: Int = 0
        Swift.withUnsafeBytes(of: &leftUUID) { leftPtr in
            Swift.withUnsafeBytes(of: &rightUUID) { rightPtr in
                for offset in (0..<MemoryLayout<ByteValue>.size).reversed() {
                    diff = Int(leftPtr.load(fromByteOffset: offset, as: UInt8.self)) - Int(rightPtr.load(fromByteOffset: offset, as: UInt8.self))
                    result = (result & (((diff - 1) & ~diff) >> 8)) | diff
                }
            }
        }
        return result < 0
    }
}

// MARK: - Codable

#if !hasFeature(Embedded)
extension UUID: Codable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let uuidString = try container.decode(String.self)
        guard let uuid = UUID(uuidString: uuidString) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Attempted to decode UUID from invalid UUID string."))
        }
        self = uuid
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.uuidString)
    }
}
#endif

// MARK: - UUID String Parsing

fileprivate extension UInt128 {

    /// Parse a UUID string and return a value in big endian order.
    static func bigEndian(uuidString string: String) -> UInt128? {
        guard string.utf8.count == 36,
            let separator = "-".utf8.first
        else {
            return nil
        }
        let characters = string.utf8
        guard characters[characters.index(characters.startIndex, offsetBy: 8)] == separator,
            characters[characters.index(characters.startIndex, offsetBy: 13)] == separator,
            characters[characters.index(characters.startIndex, offsetBy: 18)] == separator,
            characters[characters.index(characters.startIndex, offsetBy: 23)] == separator,
            let a = String(characters[characters.startIndex..<characters.index(characters.startIndex, offsetBy: 8)]),
            let b = String(characters[characters.index(characters.startIndex, offsetBy: 9)..<characters.index(characters.startIndex, offsetBy: 13)]),
            let c = String(characters[characters.index(characters.startIndex, offsetBy: 14)..<characters.index(characters.startIndex, offsetBy: 18)]),
            let d = String(characters[characters.index(characters.startIndex, offsetBy: 19)..<characters.index(characters.startIndex, offsetBy: 23)]),
            let e = String(characters[characters.index(characters.startIndex, offsetBy: 24)..<characters.index(characters.startIndex, offsetBy: 36)])
        else { return nil }
        let hexadecimal = (a + b + c + d + e)
        guard hexadecimal.utf8.count == 32,
            let value = UInt128(hexadecimal: hexadecimal)
        else {
            return nil
        }
        return value.bigEndian
    }

    /// Generate UUID string, e.g. `0F4DD6A4-0F71-48EF-98A5-996301B868F9` from a value initialized in its big endian order.
    var bigEndianUUIDString: String {

        let a =
            (bytes.0.toHexadecimal()
                + bytes.1.toHexadecimal()
                + bytes.2.toHexadecimal()
                + bytes.3.toHexadecimal())

        let b =
            (bytes.4.toHexadecimal()
                + bytes.5.toHexadecimal())

        let c =
            (bytes.6.toHexadecimal()
                + bytes.7.toHexadecimal())

        let d =
            (bytes.8.toHexadecimal()
                + bytes.9.toHexadecimal())

        let e =
            (bytes.10.toHexadecimal()
                + bytes.11.toHexadecimal()
                + bytes.12.toHexadecimal()
                + bytes.13.toHexadecimal()
                + bytes.14.toHexadecimal()
                + bytes.15.toHexadecimal())

        return a + "-" + b + "-" + c + "-" + d + "-" + e
    }
}

fileprivate extension UInt128 {

    /// Reinterpret a 16-byte tuple as a `UInt128`, preserving byte order exactly (no endian conversion).
    init(bytes: UUID.ByteValue) {
        self = Swift.withUnsafeBytes(of: bytes) { $0.loadUnaligned(as: UInt128.self) }
    }

    /// Reinterpret `self`'s raw memory as a 16-byte tuple, preserving byte order exactly (no endian conversion).
    var bytes: UUID.ByteValue {
        var value = self
        return Swift.withUnsafeBytes(of: &value) { $0.loadUnaligned(as: UUID.ByteValue.self) }
    }

    init?(hexadecimal string: String) {
        guard string.utf8.count == 32 else { return nil }
        var result: UInt128 = 0
        for byte in string.utf8 {
            let nibble: UInt128
            switch byte {
            case 0x30...0x39: nibble = UInt128(byte - 0x30)        // '0'-'9'
            case 0x41...0x46: nibble = UInt128(byte - 0x41 + 10)   // 'A'-'F'
            case 0x61...0x66: nibble = UInt128(byte - 0x61 + 10)   // 'a'-'f'
            default: return nil
            }
            result = (result << 4) | nibble
        }
        self = result
    }
}

fileprivate extension UInt8 {

    func toHexadecimal() -> String {
        let hexDigits: [Character] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
        let high = Int(self >> 4)
        let low = Int(self & 0x0F)
        return String([hexDigits[high], hexDigits[low]])
    }
}

#endif
