//  Copyright © 2018 Compass. All rights reserved.

import Foundation

class Scheduler {
    let delay: TimeInterval
    let repeats: Bool

    let event = Observable<Void>()
    private var timer: Timer?

    init(_ delay: TimeInterval, repeats: Bool = true) {
        self.delay = delay
        self.repeats = repeats
    }

    @objc private func onNext() {
        event.on(.next(()))
    }

    func reset() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(onNext), userInfo: nil, repeats: true)
    }
}
