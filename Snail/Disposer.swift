//  Copyright © 2019 Compass. All rights reserved.

import Foundation

public protocol DisposableType {
    func dispose()
}

public class Disposer {
    private(set) var disposables: [DisposableType] = []
    private let recursiveLock = NSRecursiveLock()

    public init() {}

    deinit {
        disposeAll()
    }

    public func disposeAll() {
        recursiveLock.lock(); defer { recursiveLock.unlock() }
        disposables.forEach { $0.dispose() }
        disposables.removeAll()
    }

    public func add(disposable: DisposableType) {
        recursiveLock.lock(); defer { recursiveLock.unlock() }
        disposables.append(disposable)
    }
}
