//  Copyright © 2019 Compass. All rights reserved.

import Foundation

public protocol DisposableType {
    func dispose()
}

public class Disposer {
    private(set) public var disposables: [DisposableType] = []

    public init() {}

    public func disposeAll() {
        disposables.forEach { $0.dispose() }
        disposables.removeAll()
    }

    public func add(disposable: DisposableType) {
        disposables.append(disposable)
    }
}
