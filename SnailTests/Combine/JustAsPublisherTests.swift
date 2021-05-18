//  Copyright © 2021 Compass. All rights reserved.

import Combine
import Foundation
@testable import Snail
import XCTest

@available(iOS 13.0, *)
class JustAsPublisherTests: XCTestCase {
    private var subscriptions: Set<AnyCancellable>!

    override func setUp() {
        subscriptions = Set<AnyCancellable>()
    }

    override func tearDown() {
        subscriptions = nil
        super.tearDown()
    }

    func testJust() {
        var result: Int?
        var done = false

        Just(1).asPublisher()
            .sink(receiveCompletion: { completion in
                if case .finished = completion {
                    done = true
                }
            },
            receiveValue: { result = $0 })
            .store(in: &subscriptions)

        XCTAssertEqual(1, result)
        XCTAssertTrue(done)
    }
}
