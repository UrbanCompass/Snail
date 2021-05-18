//  Copyright © 2021 Compass. All rights reserved.

import Combine
import Foundation

@available(iOS 13.0, *)
public class SnailPublisher<Upstream: ObservableType>: Publisher {
    public typealias Output = Upstream.T
    public typealias Failure = Error

    private let upstream: Upstream

    init(upstream: Upstream) {
        self.upstream = upstream
    }

    public func receive<S: Combine.Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
        subscriber.receive(subscription: SnailSubscription(upstream: upstream,
                                                           downstream: subscriber))
    }
}
