//  Copyright © 2016 Compass. All rights reserved.

public class Observable<T> : ObservableType {
    public typealias E = T
    private var isStopped: Int32 = 0
    var eventHandlers: [(Event<E>) -> Void] = []
    private var test: [(next: ((T) -> Void)?, done: (() -> Void)?, error: ((Error) -> Void)?)] = []

    public func subscribe(_ handler: @escaping (Event<E>) -> Void) {
        eventHandlers.append(handler)
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

    public func subscribe(onNext: ((T) -> Void)? = nil, onError: ((Error) -> Void)? = nil, onDone: (() -> Void)? = nil) {
        eventHandlers.append(createHandler(onNext: onNext, onError: onError, onDone: onDone))
    }

    public func on(_ event: Event<E>) {
        switch event {
        case .next:
            guard isStopped == 0 else {
                return
            }
            eventHandlers.forEach { $0(event) }
        case .error, .done:
            if OSAtomicCompareAndSwap32Barrier(0, 1, &isStopped) {
                eventHandlers.forEach { $0(event) }
            }
        }
    }
}
