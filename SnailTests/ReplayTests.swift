//  Copyright © 2016 Compass. All rights reserved.

import Foundation
import XCTest
@testable import Snail

class ReplayTests: XCTestCase {
    private var subject: Replay<String>?

    override func setUp() {
        super.setUp()
        subject = Replay(2)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testReplay() {
        var strings: [String] = []
        subject?.on(.next("1"))
        subject?.on(.next("2"))
        subject?.on(.done)
        _ = subject?.subscribe(onNext: { string in strings.append(string) })

        XCTAssertEqual(strings[0], "1")
        XCTAssertEqual(strings[1], "2")
    }

    func testMultipleSubscribers() {
        var strings: [String] = []
        var more: [String] = []
        subject?.on(.next("1"))
        subject?.on(.next("2"))
        _ = subject?.subscribe(onNext: { strings.append($0) })

        subject?.on(.next("3"))
        _ = subject?.subscribe(onNext: { more.append($0) })

        XCTAssertEqual(strings[0], "1")
        XCTAssertEqual(more[0], "2")
        XCTAssertEqual(more.count, 2)
    }

    func testReplayQueue() {
        var isMainQueue = false
        let exp = expectation(description: "queue")

        subject?.on(.next("1"))
        DispatchQueue.global().async {
            _ = self.subject?.subscribe(queue: .main, onNext: { _ in
                isMainQueue = Thread.isMainThread
                exp.fulfill()
            })
        }

        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
            XCTAssertEqual(isMainQueue, true)
        }
    }

    func testReplayOnMainThreadNotifiedOnMain() {
        var isMainQueue = false
        let exp = expectation(description: "queue")

        subject?.on(.next("1"))

        DispatchQueue.global().async {
            self.subject?.on(.main).subscribe(onNext: { _ in
                isMainQueue = Thread.isMainThread
                exp.fulfill()
            })
        }

        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
            XCTAssertEqual(isMainQueue, true)
        }
    }
}
