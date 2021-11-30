import CoreGraphics

public struct Size {
    public let width: Dimension
    public let height: Dimension

    public enum Dimension {
        case none
        case fixed(constant: CGFloat)
        case relative(multiplier: CGFloat, constant: CGFloat)
    }

    public init(width: Dimension = .none, height: Dimension = .none) {
        self.width = width
        self.height = height
    }
}

extension Size.Dimension {
    public static var equal: Size.Dimension {
        .relative(multiplier: 1, constant: 0)
    }
}

extension Size.Dimension: ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
    public init(integerLiteral value: Int) {
        self = .fixed(constant: CGFloat(value))
    }

    public init(floatLiteral value: Float) {
        self = .fixed(constant: CGFloat(value))
    }

    public typealias IntegerLiteralType = Int
    public typealias FloatLiteralType = Float
}

extension Size.Dimension: Equatable { }
