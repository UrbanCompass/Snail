//  Copyright © 2016 Compass. All rights reserved.

import Foundation

public class Variable<T> {
    let subject: Replay<T>
    var lock = NSRecursiveLock()
    var currentValue: T
    private let disposer = Disposer()

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

    public func bind(to variable: Variable<T>) -> Subscriber<T> {
        return variable.asObservable().subscribe(onNext: { [weak self] value in
            self?.value = value
        })
    }

    public func map<U>(_ transform: @escaping (T) -> U) -> Variable<U> {
        let newVariable = Variable<U>(transform(value))
        asObservable().subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            newVariable.value = transform(self.value)
        }).add(to: disposer)
        return newVariable
    }

    deinit {
        subject.on(.done)
    }
}
