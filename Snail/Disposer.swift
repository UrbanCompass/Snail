//  Copyright © 2019 Compass. All rights reserved.

import Foundation

public protocol DisposableType {
    func dispose()
}

public class Disposer {
    public var disposables: [DisposableType] = []
    public init() {}
    public func clear() {
        disposables.forEach { $0.dispose() }
        disposables = []
    }
}
