import UIKit

extension UIView {
    public convenience init(forAutoLayout disableAutoresizingMask: Bool) {
        self.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = !disableAutoresizingMask
    }
}
