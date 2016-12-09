//  Copyright © 2016 Compass. All rights reserved.

import Foundation
import XCTest
@testable import Snail

class ObservableTests: XCTestCase {
    enum TestError: Error {
        case test
    }

    private var subject: Observable<String>?
    private var strings: [String]?
    private var error: Error?
    private var done: Bool?

    override func setUp() {
        super.setUp()
        subject = Observable<String>()
        strings = []
        error = nil
        done = nil
        subject?.subscribe(
            onNext: { string in self.strings?.append(string) },
            onError: { error in self.error = error },
            onDone: { self.done = true })
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
        XCTAssert(more.first == "1")
    }

    func testOnNext() {
        subject?.on(.next("1"))
        subject?.on(.next("2"))
        XCTAssert(strings?[0] == "1")
        XCTAssert(strings?[1] == "2")
    }

    func testOnDone() {
        subject?.on(.next("1"))
        subject?.on(.next("2"))
        subject?.on(.done)
        subject?.on(.next("3"))
        XCTAssert(strings?.count == 2)
        XCTAssert(strings?[0] == "1")
        XCTAssert(strings?[1] == "2")
        XCTAssert(done == true)
    }

    func testOnError() {
        subject?.on(.next("1"))
        subject?.on(.next("2"))
        subject?.on(.error(TestError.test))
        subject?.on(.next("3"))
        XCTAssert(strings?.count == 2)
        XCTAssert(strings?[0] == "1")
        XCTAssert(strings?[1] == "2")
        XCTAssert((error as? TestError) == TestError.test)
    }

    func testMultipleSubscribers() {
        var more: [String] = []
        subject?.subscribe(onNext: { string in
            more.append(string)
        })
        subject?.on(.next("1"))
        XCTAssert(strings?.first == more.first)
    }
}
