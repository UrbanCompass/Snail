//  Copyright © 2016 Compass. All rights reserved.

public extension UIView {
    public var tap: Observable<Void> {
        get {
            if let button = self as? UIButton {
                return button.controlEvent(.touchUpInside)
            }
            let tap = UITapGestureRecognizer()
            addGestureRecognizer(tap)
            return tap.asObservable()
        }
    }
}
