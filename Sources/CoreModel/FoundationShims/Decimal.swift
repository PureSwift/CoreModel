//
//  Decimal.swift
//  CoreModel
//
//  Minimal Foundation-free `Decimal` for platforms without Foundation
//  (e.g. Embedded Swift). Storage-layer only: normalized decimal-string
//  representation, no arithmetic. Not a replacement for `Foundation.Decimal`
//  in numeric contexts.
//

#if !canImport(FoundationEssentials) && !canImport(Foundation)

public struct Decimal: Sendable {

    /// Normalized decimal string: optional `-` sign, digits, optional `.` fraction
    /// with no trailing zeros; `-0` and `-0.0` normalize to `0`.
    private let normalized: String

    public init?(string: String) {
        guard let normalized = Decimal.normalize(string) else {
            return nil
        }
        self.normalized = normalized
    }

    private init(normalized: String) {
        self.normalized = normalized
    }

    private static func normalize(_ string: String) -> String? {
        let chars = Array(string.utf8)
        guard chars.isEmpty == false else { return nil }

        var index = 0
        var negative = false
        if chars[index] == UInt8(ascii: "-") {
            negative = true
            index += 1
        }
        guard index < chars.count else { return nil }

        var integerDigits: [UInt8] = []
        while index < chars.count, chars[index] >= UInt8(ascii: "0"), chars[index] <= UInt8(ascii: "9") {
            integerDigits.append(chars[index])
            index += 1
        }
        guard integerDigits.isEmpty == false else { return nil }

        var fractionDigits: [UInt8] = []
        if index < chars.count, chars[index] == UInt8(ascii: ".") {
            index += 1
            while index < chars.count, chars[index] >= UInt8(ascii: "0"), chars[index] <= UInt8(ascii: "9") {
                fractionDigits.append(chars[index])
                index += 1
            }
            guard fractionDigits.isEmpty == false else { return nil }
        }
        guard index == chars.count else { return nil }

        // Strip leading zeros from the integer part (keep at least one digit).
        var integerStart = 0
        while integerStart < integerDigits.count - 1, integerDigits[integerStart] == UInt8(ascii: "0") {
            integerStart += 1
        }
        integerDigits = Array(integerDigits[integerStart...])

        // Strip trailing zeros from the fraction part.
        var fractionEnd = fractionDigits.count
        while fractionEnd > 0, fractionDigits[fractionEnd - 1] == UInt8(ascii: "0") {
            fractionEnd -= 1
        }
        fractionDigits = Array(fractionDigits[..<fractionEnd])

        let isZero = integerDigits.allSatisfy { $0 == UInt8(ascii: "0") } && fractionDigits.isEmpty

        var result = ""
        if negative && !isZero {
            result += "-"
        }
        result += String(decoding: integerDigits, as: UTF8.self)
        if fractionDigits.isEmpty == false {
            result += "." + String(decoding: fractionDigits, as: UTF8.self)
        }
        return result
    }
}

// MARK: - Equatable, Hashable

extension Decimal: Equatable, Hashable {

    public static func == (lhs: Decimal, rhs: Decimal) -> Bool {
        lhs.normalized == rhs.normalized
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(normalized)
    }
}

// MARK: - CustomStringConvertible

extension Decimal: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        normalized
    }

    public var debugDescription: String {
        description
    }
}

// MARK: - Codable

#if !hasFeature(Embedded)
extension Decimal: Codable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let value = Decimal(string: string) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Attempted to decode Decimal from invalid string."))
        }
        self = value
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}
#endif

#endif
