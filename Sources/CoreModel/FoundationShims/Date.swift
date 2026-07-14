//
//  Date.swift
//  CoreModel
//
//  Minimal Foundation-free `Date` for platforms without Foundation
//  (e.g. Embedded Swift). Not API-complete — storage-layer round-tripping only.
//

#if !canImport(FoundationEssentials) && !canImport(Foundation)

public typealias TimeInterval = Double

public struct Date: Sendable {

    /// Number of seconds relative to the reference date of Jan 1, 2001, 00:00:00 UTC.
    public var timeIntervalSinceReferenceDate: TimeInterval

    public init(timeIntervalSinceReferenceDate: TimeInterval) {
        self.timeIntervalSinceReferenceDate = timeIntervalSinceReferenceDate
    }
}

extension Date {

    /// Seconds between the Unix epoch (Jan 1, 1970) and the reference date (Jan 1, 2001).
    private static let referenceDateToUnixEpoch: TimeInterval = 978307200

    public init(timeIntervalSince1970: TimeInterval) {
        self.init(timeIntervalSinceReferenceDate: timeIntervalSince1970 - Self.referenceDateToUnixEpoch)
    }

    public var timeIntervalSince1970: TimeInterval {
        timeIntervalSinceReferenceDate + Self.referenceDateToUnixEpoch
    }

    public func timeIntervalSince(_ other: Date) -> TimeInterval {
        timeIntervalSinceReferenceDate - other.timeIntervalSinceReferenceDate
    }

    public func addingTimeInterval(_ interval: TimeInterval) -> Date {
        Date(timeIntervalSinceReferenceDate: timeIntervalSinceReferenceDate + interval)
    }

    public mutating func addTimeInterval(_ interval: TimeInterval) {
        timeIntervalSinceReferenceDate += interval
    }

    public static func + (lhs: Date, rhs: TimeInterval) -> Date {
        lhs.addingTimeInterval(rhs)
    }

    public static func - (lhs: Date, rhs: TimeInterval) -> Date {
        lhs.addingTimeInterval(-rhs)
    }

    public static func - (lhs: Date, rhs: Date) -> TimeInterval {
        lhs.timeIntervalSince(rhs)
    }

    public static func += (lhs: inout Date, rhs: TimeInterval) {
        lhs.addTimeInterval(rhs)
    }

    public static func -= (lhs: inout Date, rhs: TimeInterval) {
        lhs.addTimeInterval(-rhs)
    }
}

// MARK: - Equatable, Comparable, Hashable

extension Date: Equatable, Comparable, Hashable {

    public static func == (lhs: Date, rhs: Date) -> Bool {
        lhs.timeIntervalSinceReferenceDate == rhs.timeIntervalSinceReferenceDate
    }

    public static func < (lhs: Date, rhs: Date) -> Bool {
        lhs.timeIntervalSinceReferenceDate < rhs.timeIntervalSinceReferenceDate
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(timeIntervalSinceReferenceDate)
    }
}

// MARK: - CustomStringConvertible

extension Date: CustomStringConvertible, CustomDebugStringConvertible {

    /// - Note: Not a Foundation-compatible ISO 8601 format — this is a
    ///   storage-layer replacement. Only used for debug/predicate description.
    public var description: String {
        timeIntervalSinceReferenceDate.description
    }

    public var debugDescription: String {
        description
    }
}

// MARK: - Codable

#if !hasFeature(Embedded)
extension Date: Codable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(timeIntervalSinceReferenceDate: try container.decode(TimeInterval.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(timeIntervalSinceReferenceDate)
    }
}
#endif

#endif
