//  Copyright © 2017 Compass. All rights reserved.

public class Unique<T: Equatable> {
    private let subject: Replay<T>
    private var lock = NSRecursiveLock()
    private var currentValue: T

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
    }

    public func asObservable() -> Observable<T> {
        return subject
    }

    deinit {
        subject.on(.done)
    }
}
