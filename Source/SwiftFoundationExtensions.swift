
import SwiftFoundation

public extension String {
    
    ///
    /// Get the substring captured by a ```RegularExpressionMatch.Range```, if any.
    ///
    /// **FIXME**: Delete if [pulled into ```SwiftFoundation```](https://github.com/PureSwift/SwiftFoundation/pull/16)
    ///
    func substring(range: RegularExpressionMatch.Range) -> String? {
        switch range {
        case .NotFound:
            return nil
        case let .Found(r):
            return substring(r)
        }
    }
    
    ///
    /// Get the substring captured by a ```Range<Int>```, if any.
    ///
    /// **FIXME**: Delete if [pulled into ```SwiftFoundation```](https://github.com/PureSwift/SwiftFoundation/pull/16)
    ///
    func substring(range: Range<Int>) -> String? {
        let indexRange = Swift.Range(start: utf8.startIndex.advancedBy(range.startIndex), end: utf8.startIndex.advancedBy(range.endIndex))
        return String(utf8[indexRange])
    }
}
