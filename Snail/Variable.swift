//  Copyright © 2016 Compass. All rights reserved.

import Foundation

public class Variable<T> {
    private let subject: Replay<T>
    private var lock = NSRecursiveLock()
    private var _value: T

    public var value: T {
        get {
            lock.lock(); defer { lock.unlock() }
            return _value
        }
        set(newValue) {
            lock.lock()
            _value = newValue
            lock.unlock()

            subject.on(.next(newValue))
        }
    }

    public init(_ value: T) {
        _value = value
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
