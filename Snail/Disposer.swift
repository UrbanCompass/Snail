//  Copyright © 2019 Compass. All rights reserved.

import Foundation

public protocol DisposableType {
    func dispose()
}

public class Disposer {
    private(set) public var disposables: [DisposableType] = []
    private let disposablesQueue = DispatchQueue(label: "snail-disposer-queue", attributes: .concurrent)

    public init() {}

    deinit {
        disposeAll()
    }

    public func disposeAll() {
        disposablesQueue.sync {
            self.disposables.forEach { $0.dispose() }
            self.disposables.removeAll()
        }
    }

    public func add(disposable: DisposableType) {
        disposablesQueue.sync {
            self.disposables.append(disposable)
        }
    }
}
