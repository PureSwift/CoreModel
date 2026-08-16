//
//  AttributeType.swift
//
//
//  Created by Alsey Coleman Miller on 8/16/23.
//

/// CoreModel Attribute type
///
/// - Note: This type was `RawRepresentable` by `String` and `CaseIterable` before
/// ``AttributeType/composite(_:)`` was introduced. Neither conformance survives an
/// associated value, so use ``scalarRawValue``, ``init(scalarRawValue:)``, and
/// ``scalarCases`` instead.
public enum AttributeType: Hashable, Sendable {

    /// Boolean number type.
    case bool

    /// 16 bit Integer number type.
    case int16

    /// Integer number type.
    case int32

    /// Integer number type.
    case int64

    /// Floating point number type.
    case float

    /// Floating point number type.
    case double

    /// Attribute is a string.
    case string

    /// Attribute is binary data.
    case data

    /// Attribute is a date.
    case date

    /// UUID
    case uuid

    /// URL
    case url

    /// Decimal
    case decimal

    /// An attribute whose value is a dictionary of named sub-attributes.
    ///
    /// Modeled on CoreData's `NSCompositeAttributeDescription`. The corresponding
    /// value is ``AttributeValue/composite(_:)``, keyed by the ``Attribute/id`` of
    /// each element.
    ///
    /// - Note: Elements are ``Attribute`` values, so an element can never be a
    /// relationship, and may itself be `.composite`. Recursion is structurally
    /// impossible: ``AttributeType`` is a value type, so no finite value contains itself.
    case composite([Attribute])
}

// MARK: - Scalar Types

public extension AttributeType {

    /// The string identifier for scalar attribute types, and `nil` for ``AttributeType/composite(_:)``.
    ///
    /// Replaces the `RawRepresentable` conformance this type had before composite
    /// attributes. The identifiers are unchanged, so persisted schemas stay readable.
    var scalarRawValue: String? {
        switch self {
        case .bool:         return "bool"
        case .int16:        return "int16"
        case .int32:        return "int32"
        case .int64:        return "int64"
        case .float:        return "float"
        case .double:       return "double"
        case .string:       return "string"
        case .data:         return "data"
        case .date:         return "date"
        case .uuid:         return "uuid"
        case .url:          return "url"
        case .decimal:      return "decimal"
        case .composite:    return nil
        }
    }

    /// Creates a scalar attribute type from its string identifier.
    ///
    /// - Returns: `nil` for unrecognized identifiers, and for `"composite"`, whose
    /// elements cannot be recovered from a string.
    init?(scalarRawValue: String) {
        switch scalarRawValue {
        case "bool":        self = .bool
        case "int16":       self = .int16
        case "int32":       self = .int32
        case "int64":       self = .int64
        case "float":       self = .float
        case "double":      self = .double
        case "string":      self = .string
        case "data":        self = .data
        case "date":        self = .date
        case "uuid":        self = .uuid
        case "url":         self = .url
        case "decimal":     self = .decimal
        default:            return nil
        }
    }

    /// Every scalar (non-composite) attribute type.
    ///
    /// Replaces the `CaseIterable` conformance, which composite attributes make
    /// impossible, since there are infinitely many composite types.
    static var scalarCases: [AttributeType] {
        [
            .bool,
            .int16,
            .int32,
            .int64,
            .float,
            .double,
            .string,
            .data,
            .date,
            .uuid,
            .url,
            .decimal
        ]
    }

    /// The elements of a composite attribute, and `nil` for scalar types.
    var elements: [Attribute]? {
        guard case let .composite(elements) = self else {
            return nil
        }
        return elements
    }

    /// Whether this is a composite attribute type.
    var isComposite: Bool {
        guard case .composite = self else {
            return false
        }
        return true
    }
}

// MARK: - CustomStringConvertible

extension AttributeType: CustomStringConvertible {

    public var description: String {
        guard case let .composite(elements) = self else {
            return scalarRawValue ?? ""
        }
        let body = elements.reduce("", {
            $0 + ($0.isEmpty ? "" : ", ") + $1.id.rawValue + ": " + $1.type.description
        })
        return "composite(" + body + ")"
    }
}

// MARK: - Codable

#if !hasFeature(Embedded)
extension AttributeType: Codable {

    internal enum CodingKeys: String, CodingKey {

        case composite
    }

    public init(from decoder: Decoder) throws {
        // Scalar types encode as a plain string, exactly as they did before composite
        // attributes existed, so previously persisted models still decode.
        if let container = try? decoder.singleValueContainer(),
            let rawValue = try? container.decode(String.self) {
            guard let scalar = AttributeType(scalarRawValue: rawValue) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Invalid attribute type \(rawValue)"
                    )
                )
            }
            self = scalar
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let elements = try container.decode([Attribute].self, forKey: .composite)
        self = .composite(elements)
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case let .composite(elements):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(elements, forKey: .composite)
        case .bool, .int16, .int32, .int64, .float, .double,
             .string, .data, .date, .uuid, .url, .decimal:
            // - Note: The scalar cases are listed explicitly rather than with `default`,
            //   so that adding a future case is a compile error here.
            assert(scalarRawValue != nil)
            var container = encoder.singleValueContainer()
            try container.encode(scalarRawValue ?? "")
        }
    }
}
#endif
