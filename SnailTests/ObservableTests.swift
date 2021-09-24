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
    private let disposer = Disposer()

    override func setUp() {
        super.setUp()
        subject = Observable()
        strings = []
        error = nil
        done = nil
        subject?.subscribe(
            onNext: { string in self.strings?.append(string) },
            onError: { error in self.error = error },
            onDone: { self.done = true }).add(to: disposer)
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
        }).add(to: disposer)
        subject?.on(.next("1"))
        XCTAssertEqual(strings?.first, more.first)
    }

    func testFiresStoppedEventOnSubscribeIfStopped() {
        subject?.on(.error(TestError.test))

        var oldError: TestError?
        subject?.subscribe(onError: { error in oldError = error as? TestError }).add(to: disposer)
        XCTAssertEqual(oldError, .test)
    }

    func testSubscribeOnMainThread() {
        var isMainQueue = false
        let exp = expectation(description: "queue")

        DispatchQueue.global().async {
            self.subject?.subscribe(queue: .main, onNext: { _ in
                exp.fulfill()
                isMainQueue = Thread.isMainThread
            }).add(to: self.disposer)
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
            }).add(to: self.disposer)
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
            }).add(to: self.disposer)
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
        let blockResult = Just(1).block()

        guard case let .success(result) = blockResult else {
            XCTFail("expected success")
            return
        }

        XCTAssertEqual(result, 1)
    }

    func testBlockFail() {
        let blockResult = Fail<Void>(TestError.test).block()
        guard case let .failure(result) = blockResult else {
            XCTFail("expected failure")
            return
        }

        XCTAssertTrue(result is TestError)
    }

    func testBlockDone() {
        let observable = Observable<String>()
        observable.on(.done)
        let blockResult = observable.block()
        guard case let .success(result) = blockResult else {
            XCTFail("expected success")
            return
        }

        XCTAssertEqual(result, nil)
    }

    func testBlockWithTimeoutSuccess() {
        let blockResult = Just(1).block(timeout: 1)
        guard case let .success(result) = blockResult else {
            XCTFail("expected success")
            return
        }

        XCTAssertEqual(result, 1)
    }

    func testBlockWithTimeoutFail() {
        let blockResult = Fail<Void>(TestError.test).block(timeout: 1)
        guard case let .failure(result) = blockResult else {
            XCTFail("expected failure")
            return
        }

        XCTAssertTrue(result is TestError)
    }

    func testBlockWithTimeoutDone() {
        let observable = Observable<String>()
        observable.on(.done)
        let blockResult = observable.block(timeout: 1)
        guard case let .success(result) = blockResult else {
            XCTFail("expected success")
            return
        }

        XCTAssertEqual(result, nil)
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
        }).add(to: disposer)
        observable.on(.next("1"))
        observable.on(.next("2"))
        waitForExpectations(timeout: delay*2) { _ in
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
        }).add(to: disposer)

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
        }).add(to: disposer)

        observable.on(.next("1"))

        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(received.count, 1)
            XCTAssertEqual(received.first, "3")
        }
    }

    func testSkipFirst() {
        let observable = Observable<String>()
        var received: [String] = []

        observable.skip(first: 2).subscribe(onNext: { received.append($0) }).add(to: disposer)

        observable.on(.next("1"))
        observable.on(.next("2"))
        observable.on(.next("3"))
        XCTAssertEqual(received.count, 1)
        XCTAssertEqual(received.first, "3")
    }

    func testSkipError() {
        let observable = Observable<String>()

        var error: TestError?
        observable.skip(first: 2).subscribe(onError: { error = $0 as? TestError }).add(to: disposer)
        observable.on(.error(TestError.test))

        XCTAssertEqual(error, .test)
    }

    func testSkipDone() {
        let observable = Observable<String>()
        var done = false

        observable.skip(first: 2).subscribe(onDone: { done = true }).add(to: disposer)
        observable.on(.done)

        XCTAssertEqual(done, true)
    }

    func testTakeFirst() {
        let observable = Observable<String>()
        var received: [String] = []

        observable.take(first: 2).subscribe(onNext: { received.append($0) }).add(to: disposer)

        observable.on(.next("1"))
        observable.on(.next("2"))
        observable.on(.next("3"))

        XCTAssertEqual(received, ["1", "2"])
    }

    func testTakeError() {
        let observable = Observable<String>()

        var error: TestError?
        observable.take(first: 2).subscribe(onError: { error = $0 as? TestError }).add(to: disposer)
        observable.on(.error(TestError.test))

        XCTAssertEqual(error, .test)
    }

    func testTakeDone() {
        let observable = Observable<String>()
        var done = false

        observable.take(first: 2).subscribe(onDone: { done = true }).add(to: disposer)
        observable.on(.done)

        XCTAssertEqual(done, true)
    }

    func testTakeDoneWhenCountIsReached() {
        let observable = Observable<String>()
        var done = false

        observable.take(first: 2).subscribe(onDone: { done = true }).add(to: disposer)
        observable.on(.next("1"))
        observable.on(.next("2"))

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
        }).add(to: disposer)

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

        subject.subscribe(onNext: { received.append($0)}).add(to: disposer)

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
        }).add(to: disposer)

        a.on(.next("1"))
        b.on(.next("2"))
        b.on(.done)

        XCTAssertEqual(received.count, 2)
        XCTAssertEqual(received.first, "1")
        XCTAssertEqual(received.last, "2")
    }

    func testMergeWithoutArray() {
        var received: [String] = []

        let a = Observable<String>()
        let b = Observable<String>()

        let subject = Observable.merge(a, b)

        subject.subscribe(onNext: { string in
            received.append(string)
        }).add(to: disposer)

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

        let subject = Observable.combineLatest(string, int)

        subject.subscribe(onNext: { string, int in
            received.append("\(string): \(int)")
        }).add(to: disposer)

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

        let subject = Observable.combineLatest(string, int)

        subject.subscribe(onNext: { string, int in
            received.append("\(string ?? "<no title>"): \(int ?? 0)")
        }).add(to: disposer)

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

        let subject = Observable.combineLatest(string, int)

        subject.subscribe(onNext: { string, int in
            received.append("\(string): \(int)")
        }, onError: { _ in
            received.append("ERROR")
        }).add(to: disposer)

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

        let subject = Observable.combineLatest(string, int)

        subject.subscribe(onError: { _ in
            received.append("ERROR")
        }).add(to: disposer)

        int.on(.error(TestError.test))
        int.on(.next(1))

        XCTAssertEqual(received.count, 1)
        XCTAssertEqual(received.first, "ERROR")
    }

    func testCombineLatestDone_whenAllDone() {
        let obs1 = Observable<String>()
        let obs2 = Observable<Int>()

        var isDone = false
        Observable.combineLatest(obs1, obs2).subscribe(onDone: { isDone = true }).add(to: disposer)

        obs1.on(.done)
        XCTAssertFalse(isDone)

        obs2.on(.done)
        XCTAssertTrue(isDone)
    }

    func testCombineLatest3() {
        let one = Observable<String>()
        let two = Observable<Int>()
        let three = Observable<Double>()

        var received = [(String, Int, Double)]()
        let subject = Observable.combineLatest(one, two, three)

        subject.subscribe(onNext: {
            received.append($0)
        }).add(to: disposer)

        one.on(.next("The string"))
        XCTAssertTrue(received.isEmpty)

        two.on(.next(1))
        XCTAssertTrue(received.isEmpty)

        three.on(.next(100.5))
        XCTAssertEqual(received[0].0, "The string")
        XCTAssertEqual(received[0].1, 1)
        XCTAssertEqual(received[0].2, 100.5)
    }

    func testCombineLatest3Error_fromSecondMember() {
        let one = Observable<String>()
        let two = Observable<Int>()
        let three = Observable<Double>()
        let subject = Observable.combineLatest(one, two, three)

        let exp = expectation(description: "combineLatest3 forwards error from observable")
        subject.subscribe(onError: { _ in exp.fulfill() }).add(to: disposer)
        two.on(.error(TestError.test))
        waitForExpectations(timeout: 1)
    }

    func testCombineLatest3Error_fromThirdMember() {
        let one = Observable<String>()
        let two = Observable<Int>()
        let three = Observable<Double>()
        let subject = Observable.combineLatest(one, two, three)

        let exp = expectation(description: "combineLatest3 forwards error from observable")
        subject.subscribe(onError: { _ in exp.fulfill() }).add(to: disposer)
        three.on(.error(TestError.test))
        waitForExpectations(timeout: 1)
    }

    func testCombineLatest3Done_whenAllDone() {
        let obs1 = Observable<String>()
        let obs2 = Observable<Int>()
        let obs3 = Observable<Double>()

        var isDone = false
        Observable.combineLatest(obs1, obs2, obs3).subscribe(onDone: { isDone = true }).add(to: disposer)

        obs1.on(.done)
        XCTAssertFalse(isDone)

        obs2.on(.done)
        XCTAssertFalse(isDone)

        obs3.on(.done)
        XCTAssertTrue(isDone)
    }

    func testCombineLatest3Optional() {
        let one = Observable<String>()
        let two = Observable<Int?>()
        let three = Observable<Double>()

        var received = [(String, Int?, Double)]()
        let subject = Observable.combineLatest(one, two, three)

        subject.subscribe(onNext: {
            received.append($0)
        }).add(to: disposer)

        one.on(.next("The string"))
        XCTAssertTrue(received.isEmpty)

        two.on(.next(nil))
        XCTAssertTrue(received.isEmpty)

        three.on(.next(100.5))
        XCTAssertEqual(received[0].0, "The string")
        XCTAssertEqual(received[0].1, nil)
        XCTAssertEqual(received[0].2, 100.5)
    }

    func testCombineLatest4() {
        let one = Observable<String>()
        let two = Observable<Int>()
        let three = Observable<Double>()
        let four = Observable<String>()

        var received = [(String, Int, Double, String)]()
        let subject = Observable.combineLatest(one, two, three, four)

        subject.subscribe(onNext: {
            received.append($0)
        }).add(to: disposer)

        one.on(.next("The string"))
        XCTAssertTrue(received.isEmpty)

        two.on(.next(1))
        XCTAssertTrue(received.isEmpty)

        three.on(.next(100.5))
        XCTAssertTrue(received.isEmpty)

        four.on(.next("The other string"))
        XCTAssertEqual(received[0].0, "The string")
        XCTAssertEqual(received[0].1, 1)
        XCTAssertEqual(received[0].2, 100.5)
        XCTAssertEqual(received[0].3, "The other string")
    }

    func testCombineLatest4Error_fromFirstMember() {
        let one = Observable<String>()
        let two = Observable<Int>()
        let three = Observable<Double>()
        let four = Observable<String>()
        let subject = Observable.combineLatest(one, two, three, four)

        let exp = expectation(description: "combineLatest4 forwards error from observable")
        subject.subscribe(onError: { _ in exp.fulfill() }).add(to: disposer)
        one.on(.error(TestError.test))
        waitForExpectations(timeout: 1)
    }

    func testCombineLatest4Error_fromSecondMember() {
        let one = Observable<String>()
        let two = Observable<Int>()
        let three = Observable<Double>()
        let four = Observable<String>()
        let subject = Observable.combineLatest(one, two, three, four)

        let exp = expectation(description: "combineLatest4 forwards error from observable")
        subject.subscribe(onError: { _ in exp.fulfill() }).add(to: disposer)
        two.on(.error(TestError.test))
        waitForExpectations(timeout: 1)
    }

    func testCombineLatest4Error_fromThirdMember() {
        let one = Observable<String>()
        let two = Observable<Int>()
        let three = Observable<Double>()
        let four = Observable<String>()
        let subject = Observable.combineLatest(one, two, three, four)

        let exp = expectation(description: "combineLatest4 forwards error from observable")
        subject.subscribe(onError: { _ in exp.fulfill() }).add(to: disposer)
        three.on(.error(TestError.test))
        waitForExpectations(timeout: 1)
    }

    func testCombineLatest4Error_fromFourthMember() {
        let one = Observable<String>()
        let two = Observable<Int>()
        let three = Observable<Double>()
        let four = Observable<String>()
        let subject = Observable.combineLatest(one, two, three, four)

        let exp = expectation(description: "combineLatest4 forwards error from observable")
        subject.subscribe(onError: { _ in exp.fulfill() }).add(to: disposer)
        four.on(.error(TestError.test))
        waitForExpectations(timeout: 1)
    }

    func testCombineLatest4Done_whenAllDone() {
        let obs1 = Observable<String>()
        let obs2 = Observable<Int>()
        let obs3 = Observable<Double>()
        let obs4 = Observable<Float>()

        var isDone = false
        Observable.combineLatest(obs1, obs2, obs3, obs4).subscribe(onDone: { isDone = true }).add(to: disposer)

        obs1.on(.done)
        XCTAssertFalse(isDone)

        obs2.on(.done)
        XCTAssertFalse(isDone)

        obs3.on(.done)
        XCTAssertFalse(isDone)

        obs4.on(.done)
        XCTAssertTrue(isDone)
    }

    func testCombineLatest4Optional() {
        let one = Observable<String>()
        let two = Observable<Int?>()
        let three = Observable<Double>()
        let four = Observable<String?>()

        var received = [(String, Int?, Double, String?)]()
        let subject = Observable.combineLatest(one, two, three, four)

        subject.subscribe(onNext: {
            received.append($0)
        }).add(to: disposer)

        one.on(.next("The string"))
        XCTAssertTrue(received.isEmpty)

        two.on(.next(nil))
        XCTAssertTrue(received.isEmpty)

        three.on(.next(100.5))
        XCTAssertTrue(received.isEmpty)

        four.on(.next(nil))
        XCTAssertEqual(received[0].0, "The string")
        XCTAssertEqual(received[0].1, nil)
        XCTAssertEqual(received[0].2, 100.5)
        XCTAssertEqual(received[0].3, nil)
    }

    func testObservableMap() {
        let observable = Observable<Int>()
        let subject = observable.map { "Number: \($0)" }
        var received = [String]()

        subject.subscribe(onNext: { received.append($0) }).add(to: disposer)

        observable.on(.next(1))
        observable.on(.next(10))

        XCTAssertEqual(received, ["Number: 1", "Number: 10"])
    }

    func testObservableMapError() {
        let observable = Observable<Int>()
        let subject = observable.map { "Number: \($0)" }

        let exp = expectation(description: "observable map forwards error")
        subject.subscribe(onError: { _ in exp.fulfill() }).add(to: disposer)

        observable.on(.error(TestError.test))

        waitForExpectations(timeout: 1)
    }

    func testObservableMapDone() {
        let observable = Observable<Int>()
        let subject = observable.map { "Number: \($0)" }

        let exp = expectation(description: "observable map forwards done")
        subject.subscribe(onDone: { exp.fulfill() }).add(to: disposer)

        observable.on(.done)

        waitForExpectations(timeout: 1)
    }

    func testObservableFilter() {
        let observable = Observable<Int>()
        let subject = observable.filter { $0 % 2 == 0 }
        var received = [Int]()

        subject.subscribe(onNext: { received.append($0) }).add(to: disposer)

        observable.on(.next(1))
        observable.on(.next(2))
        observable.on(.next(8))
        observable.on(.next(5))

        XCTAssertEqual(received, [2, 8])
    }

    func testObservableFilterError() {
        let observable = Observable<Int>()
        let subject = observable.filter { $0 % 2 == 0 }

        let exp = expectation(description: "observable filter forwards error")
        subject.subscribe(onError: { _ in exp.fulfill() }).add(to: disposer)

        observable.on(.error(TestError.test))

        waitForExpectations(timeout: 1)
    }

    func testObservableFilterDone() {
        let observable = Observable<Int>()
        let subject = observable.filter { $0 % 2 == 0 }

        let exp = expectation(description: "observable filter forwards done")
        subject.subscribe(onDone: { exp.fulfill() }).add(to: disposer)

        observable.on(.done)

        waitForExpectations(timeout: 1)
    }

    func testObservableFlatMap() {
        let fetchTrigger = Observable<Void>()
        let subject = fetchTrigger.flatMap { Variable(100).asObservable() }
        var received = [Int]()

        subject.subscribe(onNext: { received.append($0) }).add(to: disposer)
        fetchTrigger.on(.next(()))

        XCTAssertEqual(received, [100])
    }

    func testObservableFlatMapError() {
        let fetchTrigger = Observable<Void>()
        let subject = fetchTrigger.flatMap { Variable(100).asObservable() }

        let exp = expectation(description: "observable flatMap forwards error")
        subject.subscribe(onError: { _ in exp.fulfill() }).add(to: disposer)
        fetchTrigger.on(.error(TestError.test))

        waitForExpectations(timeout: 1)
    }

    func testObservableFlatMapDone() {
        let fetchTrigger = Observable<Void>()
        let subject = fetchTrigger.flatMap { Variable(100).asObservable() }

        let exp = expectation(description: "observable flatMap forwards done")
        subject.subscribe(onDone: { exp.fulfill() }).add(to: disposer)
        fetchTrigger.on(.done)

        waitForExpectations(timeout: 1)
    }

    func testObservableDataRace() {
        let subject = Observable<String>()
        DispatchQueue.global().async {
            subject.on(.next("global - async"))
        }

        subject.on(.next("sync"))

        DispatchQueue.main.async {
            subject.on(.next("main - async"))
        }
    }

    func testZipNonOptional() {
        var received: [String] = []

        let string = Observable<String>()
        let int = Observable<Int>()

        let subject = Observable.zip(string, int)

        subject.subscribe(onNext: { string, int in
            received.append("\(string): \(int)")
        })
        .add(to: disposer)

        string.on(.next("The value"))
        string.on(.next("The number"))
        int.on(.next(1))
        int.on(.next(2))
        string.on(.next("The digit"))
        int.on(.next(3))
        int.on(.done)

        XCTAssertEqual(received.count, 3)
        XCTAssertEqual(received[0], "The value: 1")
        XCTAssertEqual(received[1], "The number: 2")
        XCTAssertEqual(received[2], "The digit: 3")
    }

    func testZipOptional() {
        var received: [String] = []

        let string = Observable<String?>()
        let int = Observable<Int?>()

        let subject = Observable.zip(string, int)

        subject.subscribe(onNext: { string, int in
            received.append("\(string ?? "<no title>"): \(int ?? 0)")
        })
        .add(to: disposer)

        string.on(.next("The value"))
        string.on(.next("The number"))
        int.on(.next(1))
        int.on(.next(nil))
        string.on(.next(nil))
        int.on(.next(3))
        string.on(.done)

        XCTAssertEqual(received.count, 3)
        XCTAssertEqual(received[0], "The value: 1")
        XCTAssertEqual(received[1], "The number: 0")
        XCTAssertEqual(received[2], "<no title>: 3")
    }

    func testZipCountEqualToSourceWithFewestEmissions() {
        var received: [String] = []

        let string = Observable<String>()
        let int = Observable<Int>()

        let subject = Observable.zip(string, int)

        subject.subscribe(onNext: { string, int in
            received.append("\(string): \(int)")
        })
        .add(to: disposer)

        string.on(.next("The value"))
        string.on(.next("The number"))
        int.on(.next(1))
        int.on(.next(2))
        string.on(.next("The digit"))
        int.on(.next(3))
        int.on(.next(4))
        int.on(.next(5))
        int.on(.next(6))
        int.on(.done)

        XCTAssertEqual(received.count, 3)
        XCTAssertEqual(received[0], "The value: 1")
        XCTAssertEqual(received[1], "The number: 2")
        XCTAssertEqual(received[2], "The digit: 3")
    }

    func testZipError() {
        let one = Observable<String>()
        let two = Observable<Int>()

        let subject = Observable.zip(one, two)

        let exp = expectation(description: "zip forwards error from observable")
        subject.subscribe(onError: { _ in exp.fulfill() }).add(to: disposer)
        one.on(.error(TestError.test))

        waitForExpectations(timeout: 1)
    }

    func testZipDone() {
        let one = Observable<String>()
        let two = Observable<Int>()

        var isDone = false
        Observable.zip(one, two).subscribe(onDone: { isDone = true }).add(to: disposer)

        one.on(.done)
        XCTAssertTrue(isDone)
    }

    func testNoDeadlock() {
        class TestObject {
            let disposer = Disposer()

            init(variable: Variable<Bool>) {
                variable.asObservable().subscribe()
                .add(to: disposer)
            }
        }

        let subject = Variable(true)
        let disposer = Disposer()

        subject.asObservable().subscribe(onNext: { _ in
            _ = TestObject(variable: subject)
        })
        .add(to: disposer)

        subject.value = true
    }

    func testRemovingFirstSubscriberWithinSubscription_NoDeadlock() {
        class TestObject {
            let disposer = Disposer()
            private let variable: Variable<Bool>

            init(variable: Variable<Bool>) {
                self.variable = variable

                self.variable.asObservable().subscribe(onNext: { _ in
                    if let firstSubscriber = variable.subject.subscribers.first {
                        self.variable.subject.removeSubscriber(subscriber: firstSubscriber)
                    }
                })
                .add(to: disposer)
            }
        }

        let subject = Variable(true)
        let disposer = Disposer()

        subject.asObservable().subscribe(onNext: { _ in
            _ = TestObject(variable: subject)
        })
        .add(to: disposer)

        subject.value = true
    }

    func testDisposerRemovesSubscriptionFromObserverOnDeinit() {
        class TestOwner {
            let disposer = Disposer()

            func bind(observable: Observable<Int>) {
                observable
                    .subscribe(queue: .main, onNext: { _ in })
                    .add(to: disposer)
            }
        }

        let observable = Observable<Int>()

        var owner: TestOwner! = TestOwner()
        owner.bind(observable: observable)

        let isDone = expectation(description: "Disposes")

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            owner = nil
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            isDone.fulfill()
        }

        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(observable.subscribers.count, 0)
        }
    }
}
