//  Copyright © 2019 Compass. All rights reserved.

import Foundation

public protocol DisposableType {
    func dispose()
}

public class Disposer {
    private(set) public var disposables: [DisposableType] = []

    public init() {}

    public func clear() {
        disposables.forEach { $0.dispose() }
        disposables = []
    }

    public func add(disposable: DisposableType) {
        disposables.append(disposable)
    }
}
