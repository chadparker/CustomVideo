//
//  ColorLabelView.swift
//  redzone
//
//  Created by Ryan May on 9/16/19.
//  Copyright © 2019 Redzone Software. All rights reserved.
//

import UIKit

public final class ColorLabelView: UIView {

    // MARK: - Subviews

    private lazy var label: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Properties

    private var inset: CGFloat = .miniTop
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?
    private var topConstraint: NSLayoutConstraint?
    private var bottomConstraint: NSLayoutConstraint?
    private var widthConstraint: NSLayoutConstraint?

    // MARK: - Init

    override public init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    // MARK: - Overrides

    override public func layoutSubviews() {
        super.layoutSubviews()
        leadingConstraint?.constant = inset * 2.0
        trailingConstraint?.constant = -inset * 2.0
        topConstraint?.constant = inset
        bottomConstraint?.constant = -inset
        widthConstraint?.constant = label.intrinsicContentSize.width
    }

    // MARK: - Setup

    public func setup(text: String, textColor: UIColor = .white, font: UIFont = .boldSystemFont(ofSize: 11.0), backgroundColor: UIColor = .redzoneRed, cornerRadius: CGFloat = 4.0, inset: CGFloat = .miniTop) {
        label.text = text
        label.textColor = textColor
        label.font = font
        self.backgroundColor = backgroundColor
        layer.cornerRadius = cornerRadius
        self.inset = inset
        setNeedsLayout()
        layoutIfNeeded()
    }

    // MARK: - Private

    private func initialize() {
        addSubview(label)

        leadingConstraint = label.leadingAnchor.constraint(equalTo: leadingAnchor).activate()
        trailingConstraint = label.trailingAnchor.constraint(equalTo: trailingAnchor).activate()
        topConstraint = label.topAnchor.constraint(equalTo: topAnchor).activate()
        bottomConstraint = label.bottomAnchor.constraint(equalTo: bottomAnchor).activate()
        widthConstraint = label.widthAnchor.constraint(equalToConstant: label.intrinsicContentSize.width).activate()

        clipsToBounds = true
    }
}
