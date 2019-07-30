//  Copyright © 2016 Compass. All rights reserved.

import Foundation
import Dispatch

public class Just<T>: Observable<T> {
    private let value: T

    public init(_ value: T) {
        self.value = value
        super.init()
    }

    @discardableResult public override func subscribe(queue: DispatchQueue? = nil, onNext: ((T) -> Void)? = nil, onError: ((Error) -> Void)? = nil, onDone: (() -> Void)? = nil) -> Subscriber<T> {
        let handler = createHandler(onNext: onNext, onError: onError, onDone: onDone)
        let subscriber = Subscriber(queue: queue, observable: self, handler: handler)
        notify(subscriber: subscriber, event: .next(value))
        notify(subscriber: subscriber, event: .done)
        return subscriber
    }
}
