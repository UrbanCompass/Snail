//  Copyright © 2016 Compass. All rights reserved.

import Foundation
import Dispatch

public class Just<T>: Observable<T> {
    private let value: T

    public init(_ value: T) {
        self.value = value
        super.init()
    }

    public override func subscribe(queue: DispatchQueue? = nil, _ handler: @escaping (Event<T>) -> Void) {
        fire(queue: queue, handler: handler, event: .next(value))
        fire(queue: queue, handler: handler, event: .done)
    }

    public override func subscribe(queue: DispatchQueue? = nil, onNext: ((T) -> Void)? = nil, onError: ((Error) -> Void)? = nil, onDone: (() -> Void)? = nil) {
        subscribe(queue: queue, createHandler(onNext: onNext, onError: onError, onDone: onDone))
    }
}
