//
//  String.swift
//  
//
//  Created by Alsey Coleman Miller on 4/12/20.
//

import Foundation

internal extension String {
    
    func compare(_ other: String, _ options: Set<FetchRequest.Predicate.Comparison.Option>, _ locale: Locale?, _ valid: ComparisonResult...) -> Bool {
        
        let locale = options.contains(.localeSensitive) ? locale : nil
        let compareOptions = CompareOptions(options.compactMap { String.CompareOptions($0) })
        let result = compare(other, options: compareOptions, range: nil, locale: locale)
        return valid.contains(result)
    }
    
    func range(of other: String, _ options: Set<FetchRequest.Predicate.Comparison.Option>, _ locale: Locale?) -> Range<String.Index>? {
        
        let locale = options.contains(.localeSensitive) ? locale : nil
        let compareOptions = CompareOptions(options.compactMap { String.CompareOptions($0) })
        return range(of: other, options: compareOptions, range: nil, locale: locale)
    }
    
    func matches(_ other: String, _ options: Set<FetchRequest.Predicate.Comparison.Option>, _ locale: Locale?) -> Bool {
        
        let locale = options.contains(.localeSensitive) ? locale : nil
        var compareOptions = String.CompareOptions(options.compactMap { String.CompareOptions($0) })
        compareOptions.insert(.regularExpression)
        return range(of: other, options: compareOptions, range: nil, locale: locale) != nil
    }
    
    func begins(with other: String, _ options: Set<FetchRequest.Predicate.Comparison.Option>, _ locale: Locale?) -> Bool {
        let locale = options.contains(.localeSensitive) ? locale : nil
        let compareOptions = CompareOptions(options.compactMap { CompareOptions($0) })
        guard let range = self.range(of: other, options: compareOptions, range: nil, locale: locale)
            else { return false }
        return range.lowerBound == self.startIndex
    }
    
    func ends(with other: String, _ options: Set<FetchRequest.Predicate.Comparison.Option>, _ locale: Locale?) -> Bool {
        let locale = options.contains(.localeSensitive) ? locale : nil
        let compareOptions = CompareOptions(options.compactMap { CompareOptions($0) })
        guard let range = self.range(of: other, options: compareOptions, range: nil, locale: locale)
            else { return false }
        return range.upperBound == self.endIndex
    }
}

internal extension StringProtocol {
    
    func begins(with other: String) -> Bool {
        guard let range = self.range(of: other, options: [], range: nil, locale: nil)
            else { return false }
        return range.lowerBound == self.startIndex
    }
}

internal extension String.CompareOptions {
    
    init?(_ option: FetchRequest.Predicate.Comparison.Option) {
        switch option {
        case .caseInsensitive:
            self = .caseInsensitive
        case .diacriticInsensitive:
            self = .diacriticInsensitive
        case .normalized,
             .localeSensitive:
            return nil
        }
    }
}
