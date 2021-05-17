//  Copyright © 2021 Compass. All rights reserved.

import Combine
import Foundation
@testable import Snail
import XCTest

@available(iOS 13.0, *)
class FailAsPublisherTests: XCTestCase {
    enum TestError: Error {
        case test
    }

    private var subject: Observable<String>!
    private var strings: [String]!
    private var error: Error?
    private var subscription: AnyCancellable?

    override func setUp() {
        super.setUp()
        subject = Fail(TestError.test)
        strings = []
        error = nil
    }

    override func tearDown() {
        subject = nil
        strings = nil
        error = nil
        subscription = nil
    }

    func testOnErrorIsRun() {
        subscription = subject.asPublisher()
            .sink(receiveCompletion: { [unowned self] completion in
                if case let .failure(underlying) = completion {
                    self.error = underlying as? TestError
                }
            },
            receiveValue: { _ in })

        XCTAssertEqual((error as? TestError), TestError.test)
    }

    func testOnNextIsNotRun() {
        subscription = subject.asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [unowned self] in strings.append($0) })
        subject?.on(.next("1"))

        XCTAssertEqual(strings?.count, 0)
    }
}
