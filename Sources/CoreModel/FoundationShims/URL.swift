//
//  URL.swift
//  CoreModel
//
//  Minimal Foundation-free `URL` for platforms without Foundation
//  (e.g. Embedded Swift). Not API-complete — storage-layer round-tripping only,
//  no real parsing/resolution.
//

#if !canImport(FoundationEssentials) && !canImport(Foundation)

public struct URL: Sendable {

    public let absoluteString: String

    public init?(string: String) {
        guard string.isEmpty == false else {
            return nil
        }
        self.absoluteString = string
    }
}

// MARK: - Equatable, Hashable

extension URL: Equatable, Hashable {}

// MARK: - CustomStringConvertible

extension URL: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        absoluteString
    }

    public var debugDescription: String {
        description
    }
}

// MARK: - Codable

#if !hasFeature(Embedded)
extension URL: Codable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let url = URL(string: string) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Attempted to decode URL from invalid string."))
        }
        self = url
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(absoluteString)
    }
}
#endif

#endif
