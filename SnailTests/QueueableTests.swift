//  Copyright © 2016 Compass. All rights reserved.

import Foundation
import XCTest
@testable import Snail

class QueueableTests: XCTestCase {
    private var subject: Queueable<String>?

    override func setUp() {
        super.setUp()
        subject = Queueable<String>()
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
        var strings: [String]? = []
        subject?.on(.next("1"))
        subject?.on(.next("2"))
        subject?
            .subscribe(onNext: { string in strings?.append(string) })
        XCTAssert(strings?[0] == "1")
        XCTAssert(strings?[1] == "2")
    }
}
