import UIKit

#if os(iOS)

/// The KeyboardPresenting protocol represents a UIViewController that resizes its content in response to keyboard
/// presentation/dismissal
public protocol KeyboardPresenting where Self: UIViewController {
    /// A constraints that moves the view's content out of the way of the keyboard (typically the bottom constraint
    /// of the content view)
    var keyboardPositionConstraint: NSLayoutConstraint { get }

    func animateAlongsideKeyboardChange(_ notification: Notification)
}

extension KeyboardPresenting {
    /// Add notification observers for keyboard presentation/dismissal. This function should be called on
    /// `viewDidLoad()`
    ///
    /// - Parameter notificationCenter: The notification center to use for notifications
    /// - Returns: An array of keyboard observers. These should be stored and removed in `deinit` using
    ///            `observers.forEach { notificationCenter.removeObserver($0) }`
    public func addKeyboardObservers(for notificationCenter: NotificationCenter = .default) -> [NSObjectProtocol] {
        var observers: [NSObjectProtocol] = []

        observers.append(notificationCenter.addObserver(forName: UIResponder.keyboardWillShowNotification,
                                                        object: nil,
                                                        queue: .main) { [weak self] notification in
            self?.handleKeyboardChange(notification)
        })

        observers.append(notificationCenter.addObserver(forName: UIResponder.keyboardWillHideNotification,
                                                        object: nil,
                                                        queue: .main) { [weak self] notification in
            self?.handleKeyboardChange(notification)
        })

        return observers
    }

    public func animateAlongsideKeyboardChange(_ notification: Notification) {
        // noop
    }

    private func handleKeyboardChange(_ notification: Notification) {
        if let windowFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let frame = view.convert(windowFrame, from: nil)
            let intersection = frame.intersection(view.bounds)

            keyboardPositionConstraint.constant = intersection.size.height
            animateAlongsideKeyboardChange(notification)

            if view.superview != nil {
                view.layoutIfNeeded()
            }
        }
    }
}

#endif
