//  Copyright © 2016 Compass. All rights reserved.

import Foundation

public class Replay<T>: Observable<T> {
    private let threshold: Int
    private var events: [Event<E>] = []

    public init(_ threshold: Int) {
        self.threshold = threshold
    }

    public override func subscribe(queue: DispatchQueue? = nil, _ handler: @escaping (Event<E>) -> Void) {
        super.subscribe(queue: queue, handler)
        replay(handler)
    }

    public override func subscribe(queue: DispatchQueue? = nil, onNext: ((T) -> Void)? = nil, onError: ((Error) -> Void)? = nil, onDone: (() -> Void)? = nil) {
        super.subscribe(queue: queue, onNext: onNext, onError: onError, onDone: onDone)
        replay(createHandler(onNext: onNext, onError: onError, onDone: onDone))
    }

    public override func on(_ event: Event<E>) {
        events.append(event)
        events = Array(events.suffix(threshold))
        super.on(event)
    }

    private func replay(_ handler: @escaping (Event<E>) -> Void) {
        events.forEach { event in handler(event) }
    }
}
