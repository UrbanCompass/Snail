//  Copyright © 2017 Compass. All rights reserved.

public class Unique<T: Equatable>: Variable<T> {
    public override var value: T {
        get {
            lock.lock(); defer { lock.unlock() }
            return currentValue
        }
        set {
            guard currentValue != newValue else {
                return
            }
            lock.lock()
            currentValue = newValue
            lock.unlock()

            subject.on(.next(newValue))
        }
    }

    public override init(_ value: T) {
        super.init(value)
        subject.on(.next(value))
    }

    public override func map<U>(transform: @escaping (T) -> U) -> Unique<U> {
        let newVariable = Unique<U>(transform(value))
        asObservable().subscribe(onNext: { _ in newVariable.value = transform(self.value) })
        return newVariable
    }
}
