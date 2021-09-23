//  Copyright © 2021 Compass. All rights reserved.

import Combine
import Foundation

@available(iOS 13.0, *)
class SnailSubscription<Upstream: ObservableType, Downstream: Combine.Subscriber>: Combine.Subscription where Downstream.Input == Upstream.T, Downstream.Failure == Error {
    private var disposable: Subscriber<Upstream.T>?
    private let buffer: DemandBuffer<Downstream>

    init(upstream: Upstream,
         downstream: Downstream) {
        buffer = DemandBuffer(subscriber: downstream)
        disposable = upstream.subscribe(queue: nil,
                                        onNext: { [weak self] value in
                                            guard let self = self else { return }
                                            _ = self.buffer.buffer(value: value)
                                        },
                                        onError: { [weak self] error in
                                            guard let self = self else { return }
                                            self.buffer.complete(completion: .failure(error))
                                        },
                                        onDone: { [weak self] in
                                            guard let self = self else { return }
                                            self.buffer.complete(completion: .finished)
                                        })
    }

    func request(_ demand: Subscribers.Demand) {
        _ = self.buffer.demand(demand)
    }

    func cancel() {
        disposable?.dispose()
        disposable = nil
    }
}
