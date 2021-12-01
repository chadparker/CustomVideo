/// An option set representing the possible axes for constraints
public struct Axes: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let horizontal = Axes(rawValue: 1 << 0)
    public static let vertical = Axes(rawValue: 1 << 1)

    public static let both: Axes = [.horizontal, .vertical]
    public static let neither: Axes = []
}
