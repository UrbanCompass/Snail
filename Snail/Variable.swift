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
    public typealias BindableType = Variable<T>

    private struct Emission<T> {
        let value: T
        let direction: Direction
    }

    private enum Direction {
        case leftToRight
        case rightToLeft
    }

    public func twoWayBind(with: BindableType) {
        var updatingLeft: Bool = false
        var updatingRight: Bool = false

        let leftEmitter: Observable<Emission<T>> = self.asObservable().map { Emission(value: $0, direction: .leftToRight) }
        let rightEmitter: Observable<Emission<T>> = with.asObservable().map { Emission(value: $0, direction: .rightToLeft) }

        Observable.merge([leftEmitter, rightEmitter]).subscribe(onNext: { element in
            switch element.direction {
            case .leftToRight:
                guard !updatingLeft else {
                    updatingLeft = false
                    return
                }
                updatingRight = true
                with.value = element.value
            case .rightToLeft:
                guard !updatingRight else {
                    updatingRight = false
                    return
                }
                updatingLeft = true
                self.value = element.value
            }
        })

        leftEmitter.on(.next(Emission(value: with.value, direction: .rightToLeft)))
    }
}
