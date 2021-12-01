import UIKit

public typealias Constraint = NSLayoutConstraint
public typealias Constraints = [Constraint]

extension Collection where Element == NSLayoutConstraint {
    public func activate() {
        NSLayoutConstraint.activate(Array(self))
    }

    public func deactivate() {
        NSLayoutConstraint.deactivate(Array(self))
    }
}

extension Array where Element == NSLayoutConstraint {
    public init(_ block: (inout [NSLayoutConstraint]) -> Void) {
        var constraints: Self = []
        block(&constraints)
        NSLayoutConstraint.activate(constraints)
        self = constraints
    }
}
