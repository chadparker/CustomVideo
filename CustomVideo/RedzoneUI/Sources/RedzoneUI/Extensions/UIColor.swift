import UIKit

extension UIColor {

    // MARK: - Dynamic Colors

    public static let redzoneBackground: UIColor = {
        #if os(tvOS)
        return UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .black : .white
        }
        #else
        return .systemBackground
        #endif
    }()

    public static let redzoneSecondaryBackground: UIColor = {
        #if os(tvOS)
        return UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .redzoneBlack : .redzoneCloudWhite
        }
        #else
        return UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .secondarySystemBackground : .redzoneCloudWhite
        }
        #endif
    }()

    public static let redzoneTertiaryBackground: UIColor = {
        #if os(tvOS)
        return UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .darkGray : .redzoneGrey
        }
        #else
        return UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .tertiarySystemBackground : .redzoneGrey
        }
        #endif
    }()

    public static let redzoneSeparatorBackground: UIColor = .separator

    #if os(iOS)
    public static let redzoneGroupedBackground: UIColor = .systemGroupedBackground
    #endif

    public static let redzoneLabel: UIColor = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? .label : .redzoneBlack
    }

    public static let redzoneSecondaryLabel: UIColor = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? .secondaryLabel : .redzoneDarkGrey
    }

    public static let redzoneTertiaryLabel: UIColor = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? .tertiaryLabel : .redzoneGrey
    }

    public static let redzoneHighlight: UIColor = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? .systemBlue : .redzoneDarkBlue
    }

    public static let redzoneAlert: UIColor = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? .systemRed : .redzoneRed
    }

    public static let redzoneSelection: UIColor = {
        #if os(tvOS)
        return .systemGray
        #else
        return .systemGray4
        #endif
    }()

    // MARK: - Redzone Colors

    public static var redzoneCloudWhite: UIColor = .init(rgbHex: 0xF3F4F8) /// Athens Gray
    public static var redzoneGrey: UIColor = .init(rgbHex: 0xACB1BB) /// Aluminium
    public static var redzoneDarkGrey: UIColor = .init(rgbHex: 0x595F6F) /// Shuttle Gray
    public static var redzoneBlack: UIColor = .init(rgbHex: 0x2C3038) /// Shark
    public static var redzoneRed: UIColor = .init(rgbHex: 0xD7363D) /// Valencia
    public static var redzonePurple: UIColor = .init(rgbHex: 0x5959CE) /// Indigo
    public static var redzoneGreen: UIColor = .init(rgbHex: 0x56BA5C) /// Fern
    public static var redzoneOrange: UIColor = .init(rgbHex: 0xFFA545) /// Yellow Orange
    public static var redzoneYellow: UIColor = .init(rgbHex: 0xF5CC12) /// Ripe Lemon
    public static var redzoneDarkBlue: UIColor = .init(rgbHex: 0x2C4772) /// San Juan
    public static var redzoneBlue: UIColor = .init(rgbHex: 0x3D63B2) /// San Marino
    public static var redzoneLightBlue: UIColor = .init(rgbHex: 0x719FFE) /// Malibu
    public static var redzoneSeparator: UIColor = .init(rgbHex: 0xC8C8CC) // UITableView Separator Color
    public static var redzoneSelectionGrey: UIColor = .init(white: 0.85, alpha: 1.0) // UITableView Selection Color
    public static var redzoneShadow: UIColor = .black.withAlphaComponent(0.75)

    // MARK: - Procedural

    public static func random(after current: UIColor? = nil, saturation: CGFloat = 0.5, brightness: CGFloat = 0.95) -> UIColor {
        GoldenRatioColorGenerator(saturation: saturation, brightness: brightness).nextColor(after: current)
    }

    // MARK: - Hex Conversions

    public convenience init(rgbHex: UInt32) {
        let components: (r: CGFloat, g: CGFloat, b: CGFloat) = (
            r: CGFloat((rgbHex >> 16) & 0xff) / 255,
            g: CGFloat((rgbHex >> 08) & 0xff) / 255,
            b: CGFloat((rgbHex >> 00) & 0xff) / 255
        )
        self.init(displayP3Red: components.r, green: components.g, blue: components.b, alpha: 1)
    }

    public convenience init(argbHex: UInt32) {
        let components: (a: CGFloat, r: CGFloat, g: CGFloat, b: CGFloat) = (
            a: CGFloat((argbHex >> 24) & 0xff) / 255,
            r: CGFloat((argbHex >> 16) & 0xff) / 255,
            g: CGFloat((argbHex >> 08) & 0xff) / 255,
            b: CGFloat((argbHex >> 00) & 0xff) / 255
        )
        self.init(displayP3Red: components.r, green: components.g, blue: components.b, alpha: components.a)
    }

    public convenience init(rgbaHex: UInt32) {
        let components: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) = (
            r: CGFloat((rgbaHex >> 24) & 0xff) / 255,
            g: CGFloat((rgbaHex >> 16) & 0xff) / 255,
            b: CGFloat((rgbaHex >> 08) & 0xff) / 255,
            a: CGFloat((rgbaHex >> 00) & 0xff) / 255
        )
        self.init(displayP3Red: components.r, green: components.g, blue: components.b, alpha: components.a)
    }

    public var rgbHex: UInt32 {
        let components = self.components
        return (components.r << 16) + (components.g << 08) + (components.b << 00)
    }

    public var argbHex: UInt32 {
        let components = self.components
        return (components.a << 24) + (components.r << 16) + (components.g << 08) + (components.b << 00)
    }

    public var rgbaHex: UInt32 {
        let components = self.components
        return (components.a << 24) + (components.r << 16) + (components.g << 08) + (components.b << 00)
    }

    public var components: (r: UInt32, g: UInt32, b: UInt32, a: UInt32) {
        // When the device supports DisplayP3, the `getRed(_:green:blue:alpha:)` can return values that
        // do not fall within the range 0 -- 1, causing a crash when converting to a hexadecimal reperesentation.
        // The CGColor implementation does not do this, so we use that where possible.

        // Convert the selected color into the DisplayP3 color space (noop if the color is already DisplayP3)
        guard let targetColorSpace = CGColorSpace(name: CGColorSpace.displayP3),
              let displayP3Color = cgColor.converted(to: targetColorSpace, intent: .perceptual, options: nil),
              let components = displayP3Color.components, displayP3Color.numberOfComponents == 4 else {

            // Fallback to UIColor implementation
            var red: CGFloat = -1
            var green: CGFloat = -1
            var blue: CGFloat = -1
            var alpha: CGFloat = -1

            getRed(&red, green: &green, blue: &blue, alpha: &alpha)

            // Clamp the values to 0 -- 1 range
            red = min(max(red, 0), 1)
            green = min(max(green, 0), 1)
            blue = min(max(blue, 0), 1)
            alpha = min(max(alpha, 0), 1)

            return (
                r: UInt32(red * 255),
                g: UInt32(green * 255),
                b: UInt32(blue * 255),
                a: UInt32(alpha * 255)
            )
        }

        return (
            r: UInt32(components[0] * 255),
            g: UInt32(components[1] * 255),
            b: UInt32(components[2] * 255),
            a: UInt32(components[3] * 255)
        )
    }
}

public protocol ColorGenerator {
    func nextColor(after color: UIColor?) -> UIColor
}

// https://martin.ankerl.com/2009/12/09/how-to-create-random-colors-programmatically/
public class GoldenRatioColorGenerator: ColorGenerator {
    public let saturation: CGFloat
    public let brightness: CGFloat

    public init(saturation: CGFloat = 0.5, brightness: CGFloat = 0.95) {
        self.saturation = saturation
        self.brightness = brightness
    }

    public func nextColor(after color: UIColor?) -> UIColor {
        let phi = (1 + sqrt(5)) / 2 // golden ratio
        let conjugate = 1 / CGFloat(phi)
        var base: CGFloat = .random(in: 0 ... 1)
        color?.getHue(&base, saturation: nil, brightness: nil, alpha: nil)

        let h = (base + conjugate).truncatingRemainder(dividingBy: 1)
        return UIColor(hue: h, saturation: saturation, brightness: brightness, alpha: 1)
    }
}
