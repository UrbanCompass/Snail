//  Copyright © 2016 Compass. All rights reserved.

import Foundation
import Dispatch

public protocol ObservableType {
    associatedtype T
    @discardableResult func subscribe(queue: DispatchQueue?, onNext: ((Self.T) -> Void)?, onError: ((Error) -> Void)?, onDone: (() -> Void)?) -> Subscriber<T>
    func on(_ event: Event<Self.T>)
    func on(_ queue: DispatchQueue) -> Observable<Self.T>
    func removeSubscribers()
    func removeSubscriber(subscriber: Subscriber<T>)
    func block() -> (result: Self.T?, error: Error?)
    func throttle(_ delay: TimeInterval) -> Observable<Self.T>
    func debounce(_ delay: TimeInterval) -> Observable<Self.T>
    func forward(to: Observable<Self.T>)
    static func merge(_ observables: [Observable<Self.T>]) -> Observable<Self.T>
}
