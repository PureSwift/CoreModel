//
//  Collection.swift
//  
//
//  Created by Alsey Coleman Miller on 4/13/20.
//

internal extension Array where Element: Equatable {
    
    func begins(with other: Self) -> Bool {
        return prefix(other.count) == other[0 ..< other.count]
    }
}

internal extension Collection where Element: Equatable {

    /// Whether `other` occurs as a contiguous subsequence of this collection.
    ///
    /// The overload the predicate engine's `.contains`/`.containedIn` string
    /// comparisons resolve to on platforms without Foundation's
    /// `StringProtocol.contains` (notably Embedded Swift, where this is the
    /// *only* candidate) — so it must implement real substring semantics, not
    /// an every-element membership test: with the latter, searching locations
    /// for "mill" also matched "1150 Timber Lane" (all of m/i/l/l appear
    /// somewhere in it).
    func contains(_ other: Self) -> Bool {
        guard !other.isEmpty else { return true }
        var start = startIndex
        while start != endIndex {
            var i = start
            var j = other.startIndex
            while j != other.endIndex, i != endIndex, self[i] == other[j] {
                i = index(after: i)
                j = index(after: j)
            }
            if j == other.endIndex { return true }
            start = index(after: start)
        }
        return false
    }
}
