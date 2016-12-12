//  Copyright © 2016 Compass. All rights reserved.

open class Observable<T> : ObservableType {
    public typealias E = T
    private var isStopped: Int32 = 0
    private var eventHandlers: [(Event<E>) -> Void] = []
    private var test: [(next: ((T) -> Void)?, done: (() -> Void)?, error: ((Error) -> Void)?)] = []

    public init() {}

    public func subscribe(_ handler: @escaping (Event<E>) -> Void) {
        eventHandlers.append(handler)
    }

    public func subscribe(onNext: ((T) -> Void)? = nil, onError: ((Error) -> Void)? = nil, onDone: (() -> Void)? = nil) {
        let handler: (Event<E>) -> Void = { event in
            switch event {
            case .next(let t): onNext?(t)
            case .error(let e): onError?(e)
            case .done: onDone?()
            }
        }
        eventHandlers.append(handler)
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
