//  Copyright © 2016 Compass. All rights reserved.

public protocol ObservableType {
    associatedtype E
    func subscribe(_ handler: @escaping (Event<E>) -> Void)
    func subscribe(onNext: ((Self.E) -> Void)?, onError: ((Error) -> Void)?, onDone: (() -> Void)?)
    func on(_ event: Event<E>)
}
