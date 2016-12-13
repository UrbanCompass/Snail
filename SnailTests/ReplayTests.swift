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

    func testEvent() {
        var strings: [String] = []
        subject?.on(.next("1"))
        subject?.subscribe { event in
            switch event {
            case .next(let string):
                strings.append(string)
            default: break
            }
        }
        XCTAssert(strings.first == "1")
    }

    func testOnNext() {
        var strings: [String] = []
        subject?.on(.next("1"))
        subject?.on(.next("2"))
        subject?.on(.done)
        subject?
            .subscribe(onNext: { string in strings.append(string) })
        XCTAssert(strings[0] == "1")
        XCTAssert(strings[1] == "2")
    }

    func testMultipleSubscribers() {
        var strings: [String] = []
        var more: [String] = []
        subject?.on(.next("1"))
        subject?.on(.next("2"))
        subject?.subscribe(onNext: { string in
            strings.append(string)
        })
        subject?.on(.next("3"))
        subject?.subscribe(onNext: { string in
            more.append(string)
        })
        XCTAssert(strings[0] == "1")
        XCTAssert(more[0] == "2")
        XCTAssert(more.count == 2)
    }

    func testReplayQueue() {
        var isMainQueue = false
        let exp = expectation(description: "queue")

        subject?.on(.next("1"))
        DispatchQueue.global().async {
            self.subject?.subscribe(queue: .main) { event in
                exp.fulfill()
                isMainQueue = Thread.isMainThread
            }
        }

        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
            XCTAssert(isMainQueue)
        }
    }
}
