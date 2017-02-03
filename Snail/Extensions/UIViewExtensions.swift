//  Copyright © 2016 Compass. All rights reserved.

#if os(iOS) || os(tvOS)
import UIKit

public extension UIView {
    public var tap: Observable<Void> {
        if let control = self as? UIControl {
            return control.controlEvent(.touchUpInside)
        }
        let tap = UITapGestureRecognizer()
        addGestureRecognizer(tap)
        return tap.asObservable()
    }
}

#endif
