//  Copyright © 2016 Compass. All rights reserved.

import Foundation

public class Fail<T>: Observable<T> {
    private let error: Error

    public init(error: Error) {
        self.error = error
    }

    public override func subscribe(_ handler: @escaping (Event<T>) -> Void) {
        handler(.error(error))
    }

    public override func subscribe(onNext: ((T) -> Void)?, onError: ((Error) -> Void)?, onDone: (() -> Void)?) {
        onError?(error)
    }
}
