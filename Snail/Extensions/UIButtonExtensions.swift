//  Copyright © 2016 Compass. All rights reserved.

extension UIButton {
    var tap: Observable<Void> {
        get {
            return ControlEvent(control: self, controlEvents: .touchUpInside).asObservable()
        }
    }
}
