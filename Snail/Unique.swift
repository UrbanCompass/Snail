//  Copyright © 2017 Compass. All rights reserved.

public class Unique<T: Equatable> {
    let subject: Replay<T>
    var lock = NSRecursiveLock()
    var currentValue: T

    public var value: T {
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

    public init(_ value: T) {
        currentValue = value
        subject = Replay<T>(1)
        self.value = value
        subject.on(.next(value))
    }

    public func asObservable() -> Observable<T> {
        return subject
    }

    public func bind(to variable: Unique<T>) {
        variable.asObservable().subscribe(onNext: { [weak self] value in
            self?.value = value
        })
    }

    public func map<U>(transform: @escaping (T) -> U) -> Unique<U> {
        let newVariable = Unique<U>(transform(value))
        asObservable().subscribe(onNext: { _ in newVariable.value = transform(self.value) })
        return newVariable
    }
}
