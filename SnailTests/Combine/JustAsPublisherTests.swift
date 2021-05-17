//  Copyright © 2021 Compass. All rights reserved.

import Combine
import Foundation
@testable import Snail
import XCTest

@available(iOS 13.0, *)
class JustAsPublisherTests: XCTestCase {
    private var subscription: AnyCancellable?

    override func tearDown() {
        subscription = nil
        super.tearDown()
    }

    func testJust() {
        var result: Int?
        var done = false

        subscription = Just(1).asPublisher()
            .sink(receiveCompletion: { completion in
                if case .finished = completion {
                    done = true
                }
            },
            receiveValue: { result = $0 })
        XCTAssertEqual(1, result)
        XCTAssertTrue(done)
    }
}
