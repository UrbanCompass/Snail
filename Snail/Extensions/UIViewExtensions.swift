//  Copyright © 2016 Compass. All rights reserved.

public extension UIView {
    public var tap: Observable<Void> {
        get {
            if let control = self as? UIControl {
                return control.controlEvent(.touchUpInside)
            }
            let tap = UITapGestureRecognizer()
            addGestureRecognizer(tap)
            return tap.asObservable()
        }
    }
}
