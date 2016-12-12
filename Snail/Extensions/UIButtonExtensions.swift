//  Copyright © 2016 Compass. All rights reserved.

public extension UIButton {
    public var tap: Observable<Void> {
        get {
            return  controlEvent(.touchUpInside)
        }
    }
}
