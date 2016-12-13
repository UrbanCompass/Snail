//  Copyright © 2016 Compass. All rights reserved.

public class Observable<T> : ObservableType {
    public typealias E = T
    private var isStopped: Int32 = 0
    var eventHandlers: [(queue: DispatchQueue?, handler: (Event<E>) -> Void)] = []

    public init() {}

    public func subscribe(queue: DispatchQueue? = nil, _ handler: @escaping (Event<E>) -> Void) {
        eventHandlers.append((queue, handler))
    }

    func createHandler(onNext: ((T) -> Void)? = nil, onError: ((Error) -> Void)? = nil, onDone: (() -> Void)? = nil) -> (Event<E>) -> Void {
        return { event in
            switch event {
            case .next(let t): onNext?(t)
            case .error(let e): onError?(e)
            case .done: onDone?()
            }
        }
    }

    public func subscribe(queue: DispatchQueue? = nil, onNext: ((T) -> Void)? = nil, onError: ((Error) -> Void)? = nil, onDone: (() -> Void)? = nil) {
        eventHandlers.append((queue, createHandler(onNext: onNext, onError: onError, onDone: onDone)))
    }

    public func on(_ event: Event<E>) {
        switch event {
        case .next:
            guard isStopped == 0 else {
                return
            }
            eventHandlers.forEach { (queue, handler) in fire(queue: queue, handler: handler, event: event) }
        case .error, .done:
            if OSAtomicCompareAndSwap32Barrier(0, 1, &isStopped) {
                eventHandlers.forEach { (queue, handler) in fire(queue: queue, handler: handler, event: event) }
            }
        }
    }

    func fire(queue: DispatchQueue?, handler: @escaping (Event<E>) -> Void, event: Event<E>) {
        guard let queue = queue else {
            handler(event)
            return
        }

        if queue == DispatchQueue.main && Thread.isMainThread {
            handler(event)
        } else {
            queue.async {
                handler(event)
            }
        }
    }
}
