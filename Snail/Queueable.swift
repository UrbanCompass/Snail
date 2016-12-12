//  Copyright © 2016 Compass. All rights reserved.

import Foundation

public class Queueable<T>: Observable<T> {
    private var events: [Event<E>] = []

    public override init() {}

    public override func subscribe(_ handler: @escaping (Event<E>) -> Void) {
        super.subscribe(handler)
        flush()
    }

    public override func subscribe(onNext: ((T) -> Void)? = nil, onError: ((Error) -> Void)? = nil, onDone: (() -> Void)? = nil) {
        super.subscribe(onNext: onNext, onError: onError, onDone: onDone)
        flush()
    }

    public override func on(_ event: Event<E>) {
        events.append(event)
        guard eventHandlers.count > 0 else {
            return
        }
        super.on(event)
    }

    private func flush() {
        events.forEach { event in
            eventHandlers.forEach { handler in handler(event) }
        }
        events.removeAll()
    }
}
