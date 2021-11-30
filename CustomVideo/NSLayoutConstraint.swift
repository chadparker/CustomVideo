import UIKit

extension NSLayoutConstraint {
    public static func activate(_ block: (inout [NSLayoutConstraint]) -> Void) {
        var constraints: [NSLayoutConstraint] = []
        block(&constraints)
        activate(constraints)
    }

    public func withPriority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
        let constraint = self
        constraint.priority = priority
        return constraint
    }

    public func withMultiplier(_ multiplier: CGFloat) -> NSLayoutConstraint {
        guard !multiplier.isNaN else { return self }

        let constraint = NSLayoutConstraint(item: firstItem as Any, attribute: firstAttribute, relatedBy: relation, toItem: secondItem as Any, attribute: secondAttribute, multiplier: multiplier, constant: constant)
        constraint.priority = priority
        constraint.shouldBeArchived = shouldBeArchived
        constraint.identifier = identifier

        let isActive = self.isActive
        self.isActive = false
        constraint.isActive = isActive

        return constraint
    }

    @discardableResult
    public func activate() -> NSLayoutConstraint {
        isActive = true
        return self
    }

    @discardableResult
    public func deactivate() -> NSLayoutConstraint {
        isActive = false
        return self
    }
}
