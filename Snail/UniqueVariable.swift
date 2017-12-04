//  Copyright © 2017 Compass. All rights reserved.

public class UniqueVariable<T: Equatable>: Variable<T> {
    public override var value: T? {
        get {
            return super.value
        }
        set {
            guard currentValue != newValue else {
                return
            }
            super.value = newValue
        }
    }
}
