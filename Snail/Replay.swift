//  Copyright © 2016 Compass. All rights reserved.

import Foundation
import Dispatch

public class Replay<T>: Observable<T> {
    private let threshold: Int
    private var events: [Event<T>] = []

    public init(_ threshold: Int) {
        self.threshold = threshold
    }

    @discardableResult public override func subscribe(queue: DispatchQueue? = nil, onNext: ((T) -> Void)? = nil, onError: ((Error) -> Void)? = nil, onDone: (() -> Void)? = nil) -> Subscriber<T> {
        replay(queue: queue, handler: createHandler(onNext: onNext, onError: onError, onDone: onDone))
        return super.subscribe(queue: queue, onNext: onNext, onError: onError, onDone: onDone)
    }

    public override func on(_ event: Event<T>) {
        switch event {
        case .next:
            events.append(event)
            events = Array(events.suffix(threshold))
        default: break
        }
        super.on(event)
    }

    public override func on(_ queue: DispatchQueue) -> Observable<T> {
        let replay = Replay<T>(threshold)
        subscribe(queue: queue,
                  onNext: { replay.on(.next($0)) },
                  onError: { replay.on(.error($0)) },
                  onDone: { replay.on(.done) })
        return replay
    }

    private func replay(queue: DispatchQueue?, handler: @escaping (Event<T>) -> Void) {
        events.forEach { event in notify(subscriber: Subscriber(queue: queue, handler: handler), event: event) }
    }
}
