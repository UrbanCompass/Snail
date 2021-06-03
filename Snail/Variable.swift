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

    deinit {
        subject.on(.done)
    }
}

extension Variable: TwoWayBind {
    private struct Emission<T> {
        let value: T
        let direction: Direction
    }

    private enum Direction {
        case leftToRight
        case rightToLeft
    }

    public func twoWayBind(with: Variable<T>) {
        let left: Observable<Emission<T>> = self.asObservable().map { Emission(value: $0, direction: .leftToRight) }
        let right: Observable<Emission<T>> = with.asObservable().map { Emission(value: $0, direction: .rightToLeft) }

        Observable.merge([left, right]).subscribe(onNext: { element in
            switch element.direction {
            case .leftToRight:
                with.currentValue = element.value
            case .rightToLeft:
                self.currentValue = element.value
            }
        })

        left.on(.next(Emission(value: with.value, direction: .rightToLeft)))
    }
}
