extension Constrainable {
    /// Create an array of constraints for positioning a view relative to another
    ///
    /// - Parameters:
    ///   - anchors: The anchors to constrain
    ///   - constrainable: The other view to constrain to
    /// - Returns: An array of disabled constraints
    public func constraints(for anchors: Anchor,
                            relativeTo constrainable: Constrainable) -> Constraints {
        var constraints = Constraints()

        if anchors.contains(.leading) {
            constraints.append(constrainable.leadingAnchor.constraint(equalTo: leadingAnchor))
        }
        if anchors.contains(.left) {
            constraints.append(constrainable.leftAnchor.constraint(equalTo: leftAnchor))
        }
        if anchors.contains(.trailing) {
            constraints.append(constrainable.trailingAnchor.constraint(equalTo: trailingAnchor))
        }
        if anchors.contains(.right) {
            constraints.append(constrainable.rightAnchor.constraint(equalTo: rightAnchor))
        }
        if anchors.contains(.top) {
            constraints.append(constrainable.topAnchor.constraint(equalTo: topAnchor))
        }
        if anchors.contains(.bottom) {
            constraints.append(constrainable.bottomAnchor.constraint(equalTo: bottomAnchor))
        }

        return constraints
    }

    /// Create an array of constraints for centering a view relative to another,
    /// optionally constraining to a set of anchors
    ///
    /// - Parameters:
    ///   - constrainable: The other view to constrain to
    ///   - axes: The axes to center along
    ///   - constrainingAnchors: The anchors to constrain the view size to
    ///   - guide: The layout guide to use for padding
    /// - Returns: An array of disabled constraints
    public func constraintsForCentering(relativeTo constrainable: Constrainable,
                                        along axes: Axes = .both,
                                        constrainingAnchors: Anchor? = nil) -> Constraints {
        var constraints = Constraints()

        if axes.contains(.horizontal) {
            constraints.append(centerXAnchor.constraint(equalTo: constrainable.centerXAnchor))
        }
        if axes.contains(.vertical) {
            constraints.append(centerYAnchor.constraint(equalTo: constrainable.centerYAnchor))
        }

        if let anchors = constrainingAnchors {
            if anchors.contains(.leading) {
                constraints.append(constrainable.leadingAnchor.constraint(lessThanOrEqualTo: leadingAnchor))
            }
            if anchors.contains(.left) {
                constraints.append(constrainable.leftAnchor.constraint(lessThanOrEqualTo: leftAnchor))
            }
            if anchors.contains(.trailing) {
                constraints.append(constrainable.trailingAnchor.constraint(greaterThanOrEqualTo: trailingAnchor))
            }
            if anchors.contains(.right) {
                constraints.append(constrainable.rightAnchor.constraint(greaterThanOrEqualTo: rightAnchor))
            }
            if anchors.contains(.top) {
                constraints.append(constrainable.topAnchor.constraint(lessThanOrEqualTo: topAnchor))
            }
            if anchors.contains(.bottom) {
                constraints.append(constrainable.bottomAnchor.constraint(greaterThanOrEqualTo: bottomAnchor))
            }
        }

        return constraints
    }

    /// Create an array of constraints for sizing a view
    ///
    /// - Parameter size: The size to constrain to
    /// - Returns: An array of disabled constraints
    public func constraints(for size: Size) -> Constraints {
        let widthConstraint: Constraint?
        let heightConstraint: Constraint?

        switch size.width {
        case .none:
            widthConstraint = nil
        case .fixed(let constant):
            widthConstraint = widthAnchor.constraint(equalToConstant: constant)
        case .relative(let multiplier, let constant):
            widthConstraint = widthAnchor.constraint(equalTo: heightAnchor, multiplier: multiplier, constant: constant)
        }

        switch size.height {
        case .none:
            heightConstraint = nil
        case .fixed(let constant):
            heightConstraint = heightAnchor.constraint(equalToConstant: constant)
        case .relative(let multiplier, let constant):
            heightConstraint = heightAnchor.constraint(equalTo: widthAnchor, multiplier: multiplier, constant: constant)
        }

        return [widthConstraint, heightConstraint].compactMap { $0 }
    }
}
