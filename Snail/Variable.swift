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

    public func bind(to variable: Variable<T>) {
        variable.asObservable().subscribe(onNext: { [weak self] value in
            self?.value = value
        })
    }

    public func map<U>(_ transform: @escaping (T) -> U) -> Variable<U> {
        let newVariable = Variable<U>(transform(value))
        asObservable().subscribe(onNext: { _ in newVariable.value = transform(self.value) })
        return newVariable
    }

    public func twoWayBind(with: Variable<T>) {
        self.value = with.value
        var skipSelfEmission: Bool = false
        var skipWithEmission: Bool = false

        self.asObservable().subscribe(onNext: { [weak with] value in
            guard !skipWithEmission else {
                skipWithEmission = false
                return
            }
            skipSelfEmission = true
            with?.value = value
        })
        with.asObservable().subscribe(onNext: { [weak self] value in
            guard !skipSelfEmission else {
                skipSelfEmission = false
                return
            }
            skipWithEmission = true
            self?.value = value
        })
    }

    deinit {
        subject.on(.done)
    }
}
