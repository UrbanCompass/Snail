//  Copyright © 2016 Compass. All rights reserved.

// swiftlint:disable file_length

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
        XCTAssertEqual(strings?[0], "1")
        XCTAssertEqual(strings?[1], "2")
    }

    func testOnDone() {
        subject?.on(.next("1"))
        subject?.on(.next("2"))
        subject?.on(.done)
        subject?.on(.next("3"))
        XCTAssertEqual(strings?.count, 2)
        XCTAssertEqual(strings?[0], "1")
        XCTAssertEqual(strings?[1], "2")
        XCTAssertEqual(done, true)
    }

    func testOnError() {
        subject?.on(.next("1"))
        subject?.on(.next("2"))
        subject?.on(.error(TestError.test))
        subject?.on(.next("3"))
        XCTAssertEqual(strings?.count, 2)
        XCTAssertEqual(strings?[0], "1")
        XCTAssertEqual(strings?[1], "2")
        XCTAssertEqual(error as? TestError, .test)
    }

    func testMultipleSubscribers() {
        var more: [String] = []
        subject?.subscribe(onNext: { string in
            more.append(string)
        })
        subject?.on(.next("1"))
        XCTAssertEqual(strings?.first, more.first)
    }

    func testFiresStoppedEventOnSubscribeIfStopped() {
        subject?.on(.error(TestError.test))

        var oldError: TestError?
        subject?.subscribe(onError: { error in oldError = error as? TestError })
        XCTAssertEqual(oldError, .test)
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
            XCTAssertEqual(isMainQueue, true)
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
            DispatchQueue.main.async {
                self.subject?.on(.next("1"))
            }
        }

        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
            XCTAssertEqual(isMainQueue, true)
        }
    }

    func testOnMainThreadNotifiedOnMain() {
        var isMainQueue = false
        let exp = expectation(description: "queue")

        DispatchQueue.global().async {
            self.subject?.on(.main).subscribe(onNext: { _ in
                exp.fulfill()
                isMainQueue = Thread.isMainThread
            })
            self.subject?.on(.next("1"))
        }

        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
            XCTAssertEqual(isMainQueue, true)
        }
    }

    func testRemovingSubscribers() {
        subject?.on(.next("1"))
        subject?.removeSubscribers()
        subject?.on(.next("2"))
        XCTAssertEqual(strings?[0], "1")
        XCTAssertEqual(strings?.count, 1)
    }

    func testRemoveSubscriber() {
        let subscriberToRemove = subject?.subscribe(
            onNext: { string in self.strings?.append(string) },
            onError: { error in self.error = error },
            onDone: { self.done = true })
        subject?.on(.next("1"))
        guard let subscriber = subscriberToRemove else {
            return
        }
        subject?.removeSubscriber(subscriber: subscriber)
        subject?.on(.next("2"))
        XCTAssertEqual(strings?.count, 3)
        XCTAssertEqual(strings?[0], "1")
        XCTAssertEqual(strings?[1], "1")
        XCTAssertEqual(strings?[2], "2")
        subject?.removeSubscriber(subscriber: subscriber)
        subject?.on(.next("3"))
        XCTAssertEqual(strings?.count, 4)
        XCTAssertEqual(strings?[0], "1")
        XCTAssertEqual(strings?[1], "1")
        XCTAssertEqual(strings?[2], "2")
        XCTAssertEqual(strings?[3], "3")
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

    func testThrottle() {
        let observable = Observable<String>()
        var received: [String] = []

        let exp = expectation(description: "throttle")
        let delay = 0.01

        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + delay) {
            exp.fulfill()
        }

        observable.throttle(delay).subscribe(onNext: {
            received.append($0)
        })
        observable.on(.next("1"))
        observable.on(.next("2"))
        waitForExpectations(timeout: delay) { _ in
            XCTAssertEqual(received.count, 1)
            XCTAssertEqual(received.first, "2")
        }
    }

    func testThrottleDelays() {
        let observable = Observable<String>()
        var received: [String] = []

        let exp = expectation(description: "debounce")
        let delay = 0.01

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
            observable.on(.next("2"))
            observable.on(.next("3"))
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
                exp.fulfill()
            }
        }

        observable.throttle(delay).subscribe(onNext: {
            received.append($0)
        })

        observable.on(.next("1"))

        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(received.count, 2)
            XCTAssertEqual(received.first, "1")
            XCTAssertEqual(received.last, "3")
        }
    }

    func testDebounce() {
        let observable = Observable<String>()
        var received: [String] = []

        let exp = expectation(description: "debounce")
        let delay = 0.02

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay/2) {
            observable.on(.next("2"))
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay/2) {
                observable.on(.next("3"))
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
                    exp.fulfill()
                }
            }
        }

        observable.debounce(delay).subscribe(onNext: {
            received.append($0)
        })

        observable.on(.next("1"))

        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(received.count, 1)
            XCTAssertEqual(received.first, "3")
        }
    }

    func testSkipFirst() {
        let observable = Observable<String>()
        var received: [String] = []

        observable.skip(first: 2).subscribe(onNext: { received.append($0) })

        observable.on(.next("1"))
        observable.on(.next("2"))
        observable.on(.next("3"))
        XCTAssertEqual(received.count, 1)
        XCTAssertEqual(received.first, "3")
    }

    func testSkipError() {
        let observable = Observable<String>()

        var error: TestError?
        observable.skip(first: 2).subscribe(onError: { error = $0 as? TestError })
        observable.on(.error(TestError.test))

        XCTAssertEqual(error, .test)
    }

    func testSkipDone() {
        let observable = Observable<String>()
        var done = false

        observable.skip(first: 2).subscribe(onDone: { done = true })
        observable.on(.done)

        XCTAssertEqual(done, true)
    }

    func testForward() {
        var received: [String] = []
        var receivedError: TestError?

        let subject = Observable<String>()
        let observable = Observable<String>()
        observable.forward(to: subject)

        subject.subscribe(onNext: { string in
            received.append(string)
        }, onError: { error in
            receivedError = error as? TestError
        })

        observable.on(.next("1"))
        observable.on(.error(TestError.test))

        XCTAssertEqual(received.count, 1)
        XCTAssertEqual(received.first, "1")
        XCTAssertEqual(receivedError, .test)
    }

    func testForwardDone() {
        var received: [String] = []

        let subject = Observable<String>()
        let observable = Observable<String>()
        observable.forward(to: subject)

        subject.subscribe(onNext: { received.append($0)})

        observable.on(.next("1"))
        observable.on(.done)

        XCTAssertEqual(received.count, 1)
        XCTAssertEqual(received.first, "1")
    }

    func testMerge() {
        var received: [String] = []

        let a = Observable<String>()
        let b = Observable<String>()

        let subject = Observable.merge([a, b])

        subject.subscribe(onNext: { string in
            received.append(string)
        })

        a.on(.next("1"))
        b.on(.next("2"))
        b.on(.done)

        XCTAssertEqual(received.count, 2)
        XCTAssertEqual(received.first, "1")
        XCTAssertEqual(received.last, "2")
    }

    func testCombineLatestNonOptional() {
        var received: [String] = []

        let string = Observable<String>()
        let int = Observable<Int>()

        let subject = Observable.combineLatest((string, int))

        subject.subscribe(onNext: { string, int in
            received.append("\(string): \(int)")
        })

        string.on(.next("The value"))
        string.on(.next("The number"))
        int.on(.next(1))
        int.on(.next(2))
        string.on(.next("The digit"))
        int.on(.next(3))
        int.on(.done)

        XCTAssertEqual(received.count, 4)
        XCTAssertEqual(received[0], "The number: 1")
        XCTAssertEqual(received[1], "The number: 2")
        XCTAssertEqual(received[2], "The digit: 2")
        XCTAssertEqual(received[3], "The digit: 3")
    }

    func testCombineLatestOptional() {
        var received: [String] = []

        let string = Observable<String?>()
        let int = Observable<Int?>()

        let subject = Observable.combineLatest((string, int))

        subject.subscribe(onNext: { string, int in
            received.append("\(string ?? "<no title>"): \(int ?? 0)")
        })

        string.on(.next("The value"))
        string.on(.next("The number"))
        int.on(.next(1))
        int.on(.next(nil))
        string.on(.next(nil))
        int.on(.next(3))
        string.on(.done)

        XCTAssertEqual(received.count, 4)
        XCTAssertEqual(received[0], "The number: 1")
        XCTAssertEqual(received[1], "The number: 0")
        XCTAssertEqual(received[2], "<no title>: 0")
        XCTAssertEqual(received[3], "<no title>: 3")
    }

    func testCombineLatestError_firstMember() {
        var received: [String] = []

        let string = Observable<String>()
        let int = Observable<Int>()

        let subject = Observable.combineLatest((string, int))

        subject.subscribe(onNext: { string, int in
            received.append("\(string): \(int)")
        }, onError: { _ in
            received.append("ERROR")
        })

        string.on(.next("The number"))
        int.on(.next(1))
        string.on(.error(TestError.test))

        string.on(.next("The digit"))
        int.on(.next(2))
        string.on(.error(TestError.test))

        XCTAssertEqual(received.count, 2)
        XCTAssertEqual(received.first, "The number: 1")
        XCTAssertEqual(received.last, "ERROR")
    }

    func testCombineLatestError_secondMember() {
        var received: [String] = []

        let string = Observable<String>()
        let int = Observable<Int>()

        let subject = Observable.combineLatest((string, int))

        subject.subscribe(onError: { _ in
            received.append("ERROR")
        })

        int.on(.error(TestError.test))
        int.on(.next(1))

        XCTAssertEqual(received.count, 1)
        XCTAssertEqual(received.first, "ERROR")
    }
}

// swiftlint:enable file_length
