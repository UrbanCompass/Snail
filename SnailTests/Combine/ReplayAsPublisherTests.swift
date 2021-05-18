//  Copyright © 2021 Compass. All rights reserved.

import Combine
import Foundation
@testable import Snail
import XCTest

@available(iOS 13.0, *)
class ReplayAsPublisherTests: XCTestCase {
    private var subject: Replay<String>!
    private var subscriptions: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        subject = Replay(2)
        subscriptions = Set<AnyCancellable>()
    }

    override func tearDown() {
        subject = nil
        subscriptions = nil
        super.tearDown()
    }

    func testReplay() {
        var strings: [String] = []
        subject?.on(.next("1"))
        subject?.on(.next("2"))
        subject?.on(.done)

        subject.asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { strings.append($0) })
            .store(in: &subscriptions)

        XCTAssertEqual(strings[0], "1")
        XCTAssertEqual(strings[1], "2")
    }
}
