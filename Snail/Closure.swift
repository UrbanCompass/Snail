//  Copyright © 2019 Compass. All rights reserved.

import Foundation

public class Closure<T>: DisposableType {
    public private(set) var closure: T?

    public init(_ closure: T) {
        self.closure = closure
    }

    public func dispose() {
        closure = nil
    }

    public func add(to disposer: Disposer) -> Closure<T> {
        disposer.add(disposable: self)
        return self
    }
}
