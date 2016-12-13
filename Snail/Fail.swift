//  Copyright © 2016 Compass. All rights reserved.

import Foundation

public class Fail<T>: Observable<T> {
    private let error: Error

    public init(_ error: Error) {
        self.error = error
    }

    public override func subscribe(queue: DispatchQueue? = nil, _ handler: @escaping (Event<T>) -> Void) {
        fire(queue: queue, handler: handler, event: .error(error))
    }

    public override func subscribe(queue: DispatchQueue? = nil, onNext: ((T) -> Void)?, onError: ((Error) -> Void)?, onDone: (() -> Void)?) {
        subscribe(queue: queue, createHandler(onNext: onNext, onError: onError, onDone: onDone))
    }
}
