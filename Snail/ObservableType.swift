//  Copyright © 2016 Compass. All rights reserved.

import Foundation
import Dispatch

public protocol ObservableType {
    associatedtype E
    func subscribe(queue: DispatchQueue?, _ handler: @escaping (Event<E>) -> Void)
    func subscribe(queue: DispatchQueue?, onNext: ((Self.E) -> Void)?, onError: ((Error) -> Void)?, onDone: (() -> Void)?)
    func on(_ event: Event<E>)
    func removeSubscribers()
}
