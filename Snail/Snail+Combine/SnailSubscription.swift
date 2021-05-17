//  Copyright © 2021 Compass. All rights reserved.

#if canImport(Combine)
import Combine
import Foundation

@available(iOS 13.0, *)
class SnailSubscription<Upstream: ObservableType, Downstream: Combine.Subscriber>: Combine.Subscription where Downstream.Input == Upstream.T, Downstream.Failure == Error {
    private var disposable: Subscriber<Upstream.T>?

    init(upstream: Upstream,
         downstream: Downstream) {
        disposable = upstream.subscribe(queue: nil,
                                        onNext: { value in
                                            _ = downstream.receive(value)
                                        },
                                        onError: { error in
                                            downstream.receive(completion: .failure(error))
                                        },
                                        onDone: {
                                            downstream.receive(completion: .finished)
                                        })
    }

    func request(_ demand: Subscribers.Demand) {
        // For now, not supporting changing any kind of demand
    }

    func cancel() {
        disposable?.dispose()
        disposable = nil
    }
}
#endif
