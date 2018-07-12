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
        subject = Observable()
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

    func testNext() {
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

    func testFiresStoppedEventOnSubscribeIfStopped() {
        subject?.on(.error(TestError.test))

        var oldError: TestError?
        subject?.subscribe(onError: { error in oldError = error as? TestError })
        XCTAssert(oldError == TestError.test)
    }

    func testSubscribeOnMainThread() {
        var isMainQueue = false
        let exp = expectation(description: "queue")

        DispatchQueue.global().async {
            self.subject?.subscribe(queue: .main, onNext: { _ in
                exp.fulfill()
                isMainQueue = Thread.isMainThread
            })
            self.subject?.on(.next("1"))
        }

        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
            XCTAssert(isMainQueue)
        }
    }

    func testSubscribeOnMainThreadNotifiedOnMain() {
        var isMainQueue = false
        let exp = expectation(description: "queue")

        DispatchQueue.global().async {
            self.subject?.subscribe(queue: .main, onNext: { _ in
                exp.fulfill()
                isMainQueue = Thread.isMainThread
            })
            self.subject?.on(.next("1"))
        }

        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
            XCTAssert(isMainQueue)
        }
    }

    func testRemovingSubscribers() {
        subject?.on(.next("1"))
        subject?.removeSubscribers()
        subject?.on(.next("2"))
        XCTAssert(strings?[0] == "1")
        XCTAssert(strings?.count == 1)
    }

    func testBlockSuccess() {
        let result = Just(1).block()
        XCTAssertEqual(result.result, 1)
        XCTAssertNil(result.error)
    }

    func testBlockFail() {
        let result = Fail<Void>(TestError.test).block()
        XCTAssertNil(result.result)
        XCTAssertNotNil(result.error)
    }

    func testBlockDone() {
        let observable = Observable<String>()
        observable.on(.done)
        let result = observable.block()
        XCTAssertNil(result.result)
        XCTAssertNil(result.error)
    }
}
