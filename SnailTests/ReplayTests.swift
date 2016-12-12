//  Copyright © 2016 Compass. All rights reserved.

import Foundation
import XCTest
@testable import Snail

class ReplayTests: XCTestCase {
    private var subject: Replay<String>?
    private var strings: [String]?

    override func setUp() {
        super.setUp()
        subject = Replay<String>(2)
        strings = []
    }

    override func tearDown() {
        super.tearDown()
    }

    func testEvent() {
        var more: [String] = []
        subject?.on(.next("1"))
        subject?.subscribe { event in
            switch event {
            case .next(let string):
                more.append(string)
            default: break
            }
        }
        XCTAssert(more.first == "1")
    }

    func testOnNext() {
        subject?.on(.next("1"))
        subject?.on(.next("2"))
        subject?
            .subscribe(onNext: { string in self.strings?.append(string) })
        XCTAssert(strings?[0] == "1")
        XCTAssert(strings?[1] == "2")
    }

    func testMultipleSubscribers() {
        var more: [String] = []
        subject?.on(.next("1"))
        subject?.on(.next("2"))
        subject?.on(.next("3"))
        subject?.subscribe(onNext: { string in
            more.append(string)
            self.strings?.append(string)
        })
        XCTAssert(strings?.first == more.first)
        XCTAssert(strings?[0] == "2")
        XCTAssert(more[1] == "3")
    }
}
