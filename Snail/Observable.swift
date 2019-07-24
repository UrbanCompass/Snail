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

    public func subscribe(queue: DispatchQueue? = nil, onNext: ((T) -> Void)? = nil, onError: ((Error) -> Void)? = nil, onDone: (() -> Void)? = nil) -> Subscriber<T> {
        let subscriber = Subscriber(queue: queue, handler: createHandler(onNext: onNext, onError: onError, onDone: onDone))
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
        for (index, element) in subscribers.enumerated() where
            element === subscriber {
                subscribers.remove(at: index)
                return
        }
    }

    public func block() -> (result: T?, error: Error?) {
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

        _ = semaphore.wait()

        return (result, error)
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

    public static func combineLatest<U>(_ input: (Observable<T>, Observable<U>)) -> Observable<(T, U)> {
        let combined = Observable<(T, U)>()

        var value0: T?
        var value1: U?

        func triggerIfNeeded() {
            if let value0 = value0, let value1 = value1 {
                combined.on(.next((value0, value1)))
            }
        }

        input.0.subscribe(onNext: {
            value0 = $0
            triggerIfNeeded()
        }, onError: {
            combined.on(.error($0))
        }, onDone: {
            combined.on(.done)
        })

        input.1.subscribe(onNext: {
            value1 = $0
            triggerIfNeeded()
        }, onError: {
            combined.on(.error($0))
        }, onDone: {
            combined.on(.done)
        })

        return combined
    }
}
