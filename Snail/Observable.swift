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
            eventHandlers.forEach { fire(eventHandler: $0, event: event) }
        case .error, .done:
            if OSAtomicCompareAndSwap32Barrier(0, 1, &isStopped) {
                eventHandlers.forEach { fire(eventHandler: $0, event: event) }
            }
        }
    }

    private func fire(eventHandler: (queue: DispatchQueue?, handler: (Event<E>) -> Void), event: Event<E>) {
        if let queue = eventHandler.queue {
            queue.async {
                eventHandler.handler(event)
            }
        } else {
            eventHandler.handler(event)
        }
    }
}
