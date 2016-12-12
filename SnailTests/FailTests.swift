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

    override func setUp() {
        super.setUp()
        subject = Fail<String>(TestError.test)
        strings = []
    }

    override func tearDown() {
        super.tearDown()
    }

    func testEvent() {
        var more: [String] = []
        subject?.subscribe { event in
            switch event {
            case .next(let string):
                more.append(string)
            default: break
            }
        }
        subject?.on(.next("1"))
        XCTAssert(more.count == 0)
    }

    func testOnNext() {
        subject?.on(.next("1"))
        subject?.on(.next("2"))
        XCTAssert(strings?.count == 0)
    }

    func testOnError() {
        subject?
            .subscribe(onError: { error in self.error = error })
        subject?.on(.next("1"))

        XCTAssert(strings?.count == 0)
        XCTAssert((error as? TestError) == TestError.test)
    }
}
