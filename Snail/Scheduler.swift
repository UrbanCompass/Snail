//  Copyright © 2018 Compass. All rights reserved.

import Foundation

public class Scheduler {
    let delay: TimeInterval
    let repeats: Bool

    public let event = Observable<Void>()
    private var timer: Timer?

    public init(_ delay: TimeInterval, repeats: Bool = true) {
        self.delay = delay
        self.repeats = repeats
    }

    @objc public func onNext() {
        event.on(.next(()))
    }

    public func start() {
        stop()
        timer = Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(onNext), userInfo: nil, repeats: repeats)
    }

    public func stop() {
        timer?.invalidate()
    }
}
