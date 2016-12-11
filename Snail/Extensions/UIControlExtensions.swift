//  Copyright © 2016 Compass. All rights reserved.

public extension UIControl {
    public func controlEvent(_ controlEvents: UIControlEvents) -> ControlEvent {
        return ControlEvent(control: self, controlEvents: controlEvents)
    }
}
