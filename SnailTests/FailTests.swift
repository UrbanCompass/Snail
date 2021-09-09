//  Copyright © 2016 Compass. All rights reserved.

import Foundation
import XCTest
@testable import Snail

class FailTests: XCTestCase {
    enum TestError: Error {
        case test
    }

    private var subject: Observable<String>?
    private var strings: [String]?
    private var error: Error?
    private var done: Bool?
    private let disposer = Disposer()

    override func setUp() {
        super.setUp()
        subject = Fail(TestError.test)
        strings = []
        error = nil
        done = nil

        subject?.subscribe(
            queue: nil,
            onNext: { [weak self] in self?.strings?.append($0) },
            onError: { self.error = $0 },
            onDone: { self.done = true }
        ).add(to: disposer)
    }

    func testOnErrorIsRun() {
        XCTAssertEqual((error as? TestError), TestError.test)
    }

    func testOnNextIsNotRun() {
        subject?.on(.next("1"))
        XCTAssertEqual(strings?.count, 0)
    }

    func testOnDoneIsNotRun() {
        XCTAssertNil(done)
    }

    func testFiresStoppedEventOnSubscribe() {
        var newError: TestError?
        done = nil

        subject?.subscribe(
            onError: { newError = $0 as? TestError },
            onDone: { self.done = true }
        ).add(to: disposer)

        XCTAssertEqual(newError, .test)
        XCTAssertNil(done)
    }
}
