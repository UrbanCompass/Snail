//  Copyright © 2016 Compass. All rights reserved.

import Foundation

public class Replay<T>: Observable<T> {
    private let threshold: Int
    private var events: [Event<E>] = []

    public init(_ threshold: Int) {
        self.threshold = threshold
    }

    public override func subscribe(_ handler: @escaping (Event<E>) -> Void) {
        super.subscribe(handler)
        replay(handler)
    }

    public override func subscribe(onNext: ((T) -> Void)? = nil, onError: ((Error) -> Void)? = nil, onDone: (() -> Void)? = nil) {
        super.subscribe(onNext: onNext, onError: onError, onDone: onDone)
        replay(createHandler(onNext: onNext, onError: onError, onDone: onDone))
    }

    public override func on(_ event: Event<E>) {
        events.append(event)
        super.on(event)
    }

    private func replay(_ handler: @escaping (Event<E>) -> Void) {
        events.suffix(threshold)
            .forEach { event in handler(event) }
    }
}
