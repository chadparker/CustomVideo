/// An option set encapsulating the NSLayoutXAxisAnchors and NSLayoutYAxisAnchors
public struct Anchor: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let leading = Anchor(rawValue: 1 << 0)
    public static let top = Anchor(rawValue: 1 << 1)
    public static let trailing = Anchor(rawValue: 1 << 2)
    public static let bottom = Anchor(rawValue: 1 << 3)
    public static let left = Anchor(rawValue: 1 << 4)
    public static let right = Anchor(rawValue: 1 << 5)

    /// All anchors: leading, trailing, top, bottom
    public static let all: Anchor = [.leading, .trailing, .top, .bottom]

    /// All fixed anchors: left, right, top, bottom
    public static let allFixed: Anchor = [.left, .right, .top, .bottom]

    /// Horizontal anchors: leading, trailing
    public static let horizontal: Anchor = [.leading, .trailing]

    /// Fixed horizontal anchors: left, right
    public static let horizontalFixed: Anchor = [.left, .right]

    /// Vertical anchors: top, bottom
    public static let vertical: Anchor = [.top, .bottom]
}
