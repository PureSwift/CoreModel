
import Cocoa
import CoreModel
import SwiftFoundation

public class ColourToDataTransformer: NSValueTransformer {
    
    override public class func transformedValueClass() -> AnyClass {
        return NSColor.self
    }
    
    override public class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override public func transformedValue(value: AnyObject?) -> AnyObject? {
        
        guard let c = value as? NSColor else {
            return nil
        }
        
        let hexstring = c.hexValue as NSString
        return hexstring.dataUsingEncoding(NSUTF8StringEncoding)
    }
    
    override public func reverseTransformedValue(value: AnyObject?) -> AnyObject? {
        
        guard let d = value as? NSData else {
            return nil
        }
        
        guard let hexstring = NSString(data: d, encoding: NSUTF8StringEncoding),
            let colour = NSColor(hexString: hexstring as String) else {
                return nil
        }
        
        return colour
    }
}

let transformer = ColourToDataTransformer()

extension NSColor {
    
    public var hexValue: String {
        
        guard let convertedColor = colorUsingColorSpaceName(NSCalibratedRGBColorSpace) else {
            fatalError("Unable to convert to RGB Color Space")
        }
        
        var redFloat: CGFloat = 0.0
        var greenFloat: CGFloat = 0.0
        var blueFloat: CGFloat = 0.0
        var alphaFloat: CGFloat = 0.0
        
        convertedColor.getRed(&redFloat, green: &greenFloat, blue: &blueFloat, alpha: &alphaFloat)
        
        let redInt = Int(redFloat * 255.0)
        let greenInt = Int(greenFloat * 255.0)
        let blueInt = Int(blueFloat * 255.0)
        
        let redHex = NSString(format: "%02x", redInt)
        let greenHex = NSString(format: "%02x", greenInt)
        let blueHex = NSString(format: "%02x", blueInt)
        
        return "#\(redHex)\(greenHex)\(blueHex)"
    }
    
    public convenience init?(hexString: String) {
        
        let pattern = "#{0,1}([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})"
        let reggy: RegularExpression
        
        do {
            reggy = try RegularExpression(pattern, options: [.ExtendedSyntax, .CaseInsensitive])
        } catch {
            assertionFailure("Couldn't make a regular expression from: \(pattern)")
            return nil
        }
        
        guard let match = reggy.match(hexString) where match.subexpressionRanges.count == 3,
            let redString = hexString.substring(match.subexpressionRanges[0]),
            let greenString = hexString.substring(match.subexpressionRanges[1]),
            let blueString = hexString.substring(match.subexpressionRanges[2]) else {
                assertionFailure("The hexString \(hexString) didn't match the regular expression \(reggy.pattern)")
                return nil
        }
        
        guard let red = Int(redString, radix: 16),
            let green = Int(greenString, radix: 16),
            let blue = Int(blueString, radix: 16) else {
                assertionFailure("Unable to parse the hexadecimal Int values for \(redString), \(greenString), or \(blueString)")
                return nil
        }
        
        let redFloat = CGFloat(red) / 255.0
        let greenFloat = CGFloat(green) / 255.0
        let blueFloat = CGFloat(blue) / 255.0
        
        self.init(calibratedRed: redFloat, green: greenFloat, blue: blueFloat, alpha: 1.0)
    }
    
}

extension NSColor: DataConvertible {
    public func toData() -> Data {
        
        guard let nsd = transformer.transformedValue(self) as? NSData else {
            fatalError("\(transformer) failed to convert \(self) to NSData")
        }
        
        return nsd.toData()
    }
    
    public static func fromData(data: Data) -> DataConvertible {
        
        let nsd = NSData(bytes: data)
        
        guard let nsc = transformer.reverseTransformedValue(nsd) as? NSColor else {
            fatalError("\(transformer) failed to convert \(data) back to NSColor")
        }
        
        return nsc
    }
    
    public func toJSON() -> JSON.Value {
        let d = toData()
        
        let encoded = Base64.encode(d)
        
        var b64 = ""
        
        encoded.forEach({ b64.append(UnicodeScalar($0)) })
        
        let jsonned = "NSColor&\(b64)"
        
        return JSON.Value.String(jsonned)
    }
}

