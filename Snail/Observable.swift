//  Copyright © 2016 Compass. All rights reserved.

import Foundation
import Dispatch

public class Observable<T>: ObservableType {
    private var isStopped: Int32 = 0
    private var stoppedEvent: Event<T>?
    var subscribers: [Subscriber<T>] = []

    public init() {}

    func createHandler(onNext: ((T) -> Void)? = nil, onError: ((Error) -> Void)? = nil, onDone: (() -> Void)? = nil) -> (Event<T>) -> Void {
        return { event in
            switch event {
            case .next(let t): onNext?(t)
            case .error(let e): onError?(e)
            case .done: onDone?()
            }
        }
    }

    @discardableResult public func subscribe(queue: DispatchQueue? = nil, onNext: ((T) -> Void)? = nil, onError: ((Error) -> Void)? = nil, onDone: (() -> Void)? = nil) -> Subscriber<T> {
        let subscriber = Subscriber(queue: queue, observable: self, handler: createHandler(onNext: onNext, onError: onError, onDone: onDone))
        if let stoppedEvent = stoppedEvent {
            notify(subscriber: subscriber, event: stoppedEvent)
            return subscriber
        }
        subscribers.append(subscriber)
        return subscriber
    }

    public func on(_ event: Event<T>) {
        switch event {
        case .next:
            guard isStopped == 0 else {
                return
            }
            subscribers.forEach { notify(subscriber: $0, event: event) }
        case .error, .done:
            if OSAtomicCompareAndSwap32Barrier(0, 1, &isStopped) {
                subscribers.forEach { notify(subscriber: $0, event: event) }
                stoppedEvent = event
            }
        }
    }

    public func on(_ queue: DispatchQueue) -> Observable<T> {
        let observable = Observable<T>()
        subscribe(queue: queue,
                  onNext: { observable.on(.next($0)) },
                  onError: { observable.on(.error($0)) },
                  onDone: { observable.on(.done) })
        return observable
    }

    public func removeSubscribers() {
        subscribers.removeAll()
    }

    public func removeSubscriber(subscriber: Subscriber<T>) {
        guard let index = subscribers.enumerated().first(where: { $0.element === subscriber })?.offset else {
            return
        }
        subscribers.remove(at: index)
    }

    public func map<U>(_ transform: @escaping (T) -> U) -> Observable<U> {
        let transformed = Observable<U>()

        subscribe(
            onNext: { value in
                transformed.on(.next(transform(value)))
            },
            onError: { error in
                transformed.on(.error(error))
            },
            onDone: {
                transformed.on(.done)
            }
        )

        return transformed
    }

    public func flatMap<U>( _ transform: @escaping (T) -> Observable<U>) -> Observable<U> {
        let flatMapped = Observable<U>()

        subscribe(
            onNext: { value in
                let obs = transform(value)
                obs.forward(to: flatMapped)
            },
            onError: { error in
                flatMapped.on(.error(error))
            },
            onDone: {
                flatMapped.on(.done)
            }
        )

        return flatMapped
    }

    public func filter(_ isIncluded: @escaping (T) -> Bool) -> Observable<T> {
        let filtered = Observable<T>()

        subscribe(
            onNext: { value in
                guard isIncluded(value) else { return }
                filtered.on(.next(value))
            },
            onError: { error in
                filtered.on(.error(error))
            }, onDone: {
                filtered.on(.done)
            }
        )

        return filtered
    }

    public func block() -> Result<T?, Error> {
        performBlock(timeout: nil)
    }

    public func block(timeout: TimeInterval) -> Result<T?, Error> {
        performBlock(timeout: timeout)
    }

    private func performBlock(timeout: TimeInterval?) -> Result<T?, Error> {
        var result: T?
        var error: Error?

        let semaphore = DispatchSemaphore(value: 0)

        subscribe(onNext: { value in
            result = value
            semaphore.signal()
        }, onError: { err in
            error = err
            semaphore.signal()
        }, onDone: {
            semaphore.signal()
        })

        if let timeout = timeout {
            _ = semaphore.wait(timeout: .now() + timeout)
        } else {
            _ = semaphore.wait()
        }

        if let error = error {
            return .failure(error)
        }

        if let result = result {
            return .success(result)
        }

        return .success(nil)
    }

    public func throttle(_ delay: TimeInterval) -> Observable<T> {
        let observable = Observable<T>()
        let scheduler = Scheduler(delay)
        scheduler.start()

        var next: T?
        scheduler.observable.subscribe(onNext: {
            guard let nextValue = next else {
                return
            }
            observable.on(.next(nextValue))
            next = nil
        })

        subscribe(onNext: { next = $0 }, onError: { observable.on(.error($0)) }, onDone: { observable.on(.done) })
        return observable
    }

    public func debounce(_ delay: TimeInterval) -> Observable<T> {
        let observable = Observable<T>()
        let scheduler = Scheduler(delay)

        var next: T?
        scheduler.observable.subscribe(onNext: {
            guard let nextValue = next else {
                return
            }
            observable.on(.next(nextValue))
            next = nil
        })

        subscribe(onNext: {
            next = $0
            scheduler.start()
        }, onError: { observable.on(.error($0)) }, onDone: { observable.on(.done) })
        return observable
    }

    public func skip(first: UInt) -> Observable<T> {
        let observable = Observable<T>()
        var count = first

        subscribe(onNext: {
            if count == 0 {
                observable.on(.next($0))
            }
            count = UInt(max(Int(count) - 1, 0))
        }, onError: {
            observable.on(.error($0))
        }, onDone: {
            observable.on(.done)
        })
        return observable
    }

    func notify(subscriber: Subscriber<T>, event: Event<T>) {
        guard let queue = subscriber.queue else {
            subscriber.handler(event)
            return
        }

        if queue == DispatchQueue.main && Thread.isMainThread {
            subscriber.handler(event)
        } else {
            queue.async {
                subscriber.handler(event)
            }
        }
    }

    public func forward(to: Observable<T>) {
        subscribe(onNext: {
            to.on(.next($0))
        }, onError: {
            to.on(.error($0))
        }, onDone: {
            to.on(.done)
        })
    }

    public static func merge(_ observables: [Observable<T>]) -> Observable<T> {
        let latest = Observable<T>()
        observables.forEach { $0.forward(to: latest) }
        return latest
    }

    public static func merge(_ observables: Observable<T>...) -> Observable<T> {
        merge(observables)
    }

    public static func combineLatest<U>(_ input1: Observable<T>, _ input2: Observable<U>) -> Observable<(T, U)> {
        let combined = Observable<(T, U)>()

        var value1: T?
        var value2: U?

        func triggerIfNeeded() {
            guard let value1 = value1,
                let value2 = value2 else {
                    return
            }
            combined.on(.next((value1, value2)))
        }

        input1.subscribe(onNext: {
            value1 = $0
            triggerIfNeeded()
        }, onError: {
            combined.on(.error($0))
        }, onDone: {
            combined.on(.done)
        })

        input2.subscribe(onNext: {
            value2 = $0
            triggerIfNeeded()
        }, onError: {
            combined.on(.error($0))
        }, onDone: {
            combined.on(.done)
        })

        return combined
    }

    public static func combineLatest<U, V>(_ input1: Observable<T>,
                                           _ input2: Observable<U>,
                                           _ input3: Observable<V>) -> Observable<(T, U, V)> {
        let combined = Observable<(T, U, V)>()

        var value1: T?
        var value2: U?
        var value3: V?

        func triggerIfNeeded() {
            guard let value1 = value1,
                let value2 = value2,
                let value3 = value3 else {
                    return
            }
            combined.on(.next((value1, value2, value3)))
        }

        input1.subscribe(onNext: {
            value1 = $0
            triggerIfNeeded()
        }, onError: {
            combined.on(.error($0))
        }, onDone: {
            combined.on(.done)
        })

        input2.subscribe(onNext: {
            value2 = $0
            triggerIfNeeded()
        }, onError: {
            combined.on(.error($0))
        }, onDone: {
            combined.on(.done)
        })

        input3.subscribe(onNext: {
            value3 = $0
            triggerIfNeeded()
        }, onError: {
            combined.on(.error($0))
        }, onDone: {
            combined.on(.done)
        })

        return combined
    }

    public static func combineLatest<U, V, K>(_ input1: Observable<T>,
                                              _ input2: Observable<U>,
                                              _ input3: Observable<V>,
                                              _ input4: Observable<K>) -> Observable<(T, U, V, K)> {
        let combined = Observable<(T, U, V, K)>()

        var value1: T?
        var value2: U?
        var value3: V?
        var value4: K?

        func triggerIfNeeded() {
            guard let value1 = value1,
                let value2 = value2,
                let value3 = value3,
                let value4 = value4 else {
                    return
            }
            combined.on(.next((value1, value2, value3, value4)))
        }

        input1.subscribe(onNext: {
            value1 = $0
            triggerIfNeeded()
        }, onError: {
            combined.on(.error($0))
        }, onDone: {
            combined.on(.done)
        })

        input2.subscribe(onNext: {
            value2 = $0
            triggerIfNeeded()
        }, onError: {
            combined.on(.error($0))
        }, onDone: {
            combined.on(.done)
        })

        input3.subscribe(onNext: {
            value3 = $0
            triggerIfNeeded()
        }, onError: {
            combined.on(.error($0))
        }, onDone: {
            combined.on(.done)
        })

        input4.subscribe(onNext: {
            value4 = $0
            triggerIfNeeded()
        }, onError: {
            combined.on(.error($0))
        }, onDone: {
            combined.on(.done)
        })

        return combined
    }
}
