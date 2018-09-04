//  Copyright © 2016 Compass. All rights reserved.

import Foundation

public class Variable<T> {
    let subject: Replay<T>
    var lock = NSRecursiveLock()
    var currentValue: T

    public var value: T {
        get {
            lock.lock(); defer { lock.unlock() }
            return currentValue
        }
        set {
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

    public func map<U>(transform: @escaping (T) -> U) -> Variable<U> {
        let newVariable = Variable<U>(transform(value))
        asObservable().subscribe(onNext: { _ in newVariable.value = transform(self.value) })
        return newVariable
    }

    deinit {
        subject.on(.done)
    }
}
