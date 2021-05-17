//  Copyright © 2021 Compass. All rights reserved.

// swiftlint:disable file_length

#if canImport(Combine)
import Combine
import Foundation
@testable import Snail
import XCTest

@available(iOS 13.0, *)
class ObservableAsPublisherTests: XCTestCase {
    enum TestError: Error {
        case test
    }

    private var subject: Observable<String>!
    private var strings: [String]!
    private var error: Error?
    private var done: Bool?
    private var disposer: Disposer!

    private var subscription: AnyCancellable?

    override func setUp() {
        super.setUp()
        subject = Observable()
        strings = []
        error = nil
        done = nil
        disposer = Disposer()
    }

    override func tearDown() {
        subject = nil
        strings = nil
        error = nil
        done = nil
        disposer = nil
        subscription = nil
        super.tearDown()
    }

    func testNext() {
        subscription = subject.asPublisher()
            .sink(receiveCompletion: { [unowned self] completion in
                switch completion {
                case .finished:
                    self.done = true
                case let .failure(underlyingError):
                    self.error = underlyingError
                }
            },
            receiveValue: { [unowned self] in self.strings?.append($0) })

        ["1", "2"].forEach { subject?.on(.next($0)) }

        XCTAssertEqual(strings, ["1", "2"])
    }

    func testOnDone() {
        subscription = subject.asPublisher()
            .sink(receiveCompletion: { [unowned self] completion in
                switch completion {
                case .finished:
                    self.done = true
                case let .failure(underlyingError):
                    self.error = underlyingError
                }
            },
            receiveValue: { [unowned self] in self.strings?.append($0) })

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
        subscription = subject.asPublisher()
            .sink(receiveCompletion: { [unowned self] completion in
                switch completion {
                case .finished:
                    self.done = true
                case let .failure(underlyingError):
                    self.error = underlyingError
                }
            },
            receiveValue: { [unowned self] in self.strings?.append($0) })

        subject?.on(.next("1"))
        subject?.on(.next("2"))
        subject?.on(.error(TestError.test))
        subject?.on(.next("3"))
        XCTAssertEqual(strings?.count, 2)
        XCTAssertEqual(strings?[0], "1")
        XCTAssertEqual(strings?[1], "2")
        XCTAssertEqual(error as? TestError, .test)
    }

    func testFiresStoppedEventOnSubscribeIfStopped() {
        subject?.on(.error(TestError.test))

        var oldError: TestError?
        subscription = subject.asPublisher()
            .sink(receiveCompletion: { completion in
                if case let .failure(underlying) = completion {
                    oldError = underlying as? TestError
                }
            }, receiveValue: { _ in })
        XCTAssertEqual(oldError, .test)
    }

    func testRemovingSubscribers() {
        subscription = subject.asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [unowned self] str in
                    self.strings.append(str)
            })
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

        subscription = subject.asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [unowned self] str in
                    self.strings.append(str)
            })

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

    func testThrottle() {
        let observable = Observable<String>()
        var received: [String] = []

        let exp = expectation(description: "throttle")
        let delay = 0.01

        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + delay) {
            exp.fulfill()
        }

        subscription = observable.throttle(delay)
            .asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { received.append($0) })

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

        subscription = observable.throttle(delay)
            .asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { received.append($0) })

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

        subscription = observable.debounce(delay)
            .asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { received.append($0) })

        observable.on(.next("1"))

        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(received.count, 1)
            XCTAssertEqual(received.first, "3")
        }
    }

    func testSkipFirst() {
        let observable = Observable<String>()
        var received: [String] = []

        subscription = observable.skip(first: 2)
            .asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { received.append($0) })

        observable.on(.next("1"))
        observable.on(.next("2"))
        observable.on(.next("3"))
        XCTAssertEqual(received.count, 1)
        XCTAssertEqual(received.first, "3")
    }

    func testSkipError() {
        let observable = Observable<String>()

        var error: TestError?
        subscription = observable.skip(first: 2)
            .asPublisher()
            .sink(receiveCompletion: { completion in
                if case let .failure(underlying) = completion {
                    error = underlying as? TestError
                }
            },
            receiveValue: { _ in })
        observable.on(.error(TestError.test))

        XCTAssertEqual(error, .test)
    }

    func testSkipDone() {
        let observable = Observable<String>()
        var done = false

        subscription = observable.skip(first: 2)
            .asPublisher()
            .sink(receiveCompletion: { completion in
                if case .finished = completion {
                    done = true
                }
            },
            receiveValue: { _ in })

        observable.on(.done)

        XCTAssertEqual(done, true)
    }

    func testTakeFirst() {
        let observable = Observable<String>()
        var received: [String] = []

        subscription = observable.take(first: 2)
            .asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { received.append($0) })

        observable.on(.next("1"))
        observable.on(.next("2"))
        observable.on(.next("3"))

        XCTAssertEqual(received, ["1", "2"])
    }

    func testTakeError() {
        let observable = Observable<String>()

        var error: TestError?
        subscription = observable.take(first: 2)
            .asPublisher()
            .sink(receiveCompletion: { completion in
                if case let .failure(underlying) = completion {
                    error = underlying as? TestError
                }
            },
            receiveValue: { _ in })

        observable.on(.error(TestError.test))

        XCTAssertEqual(error, .test)
    }

    func testTakeDone() {
        let observable = Observable<String>()
        var done = false

        subscription = observable.take(first: 2)
            .asPublisher()
            .sink(receiveCompletion: { completion in
                if case .finished = completion {
                    done = true
                }
            },
            receiveValue: { _ in })

        observable.on(.done)

        XCTAssertEqual(done, true)
    }

    func testTakeDoneWhenCountIsReached() {
        let observable = Observable<String>()
        var done = false

        subscription = observable.take(first: 2)
            .asPublisher()
            .sink(receiveCompletion: { completion in
                if case .finished = completion {
                    done = true
                }
            },
            receiveValue: { _ in })

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

        subscription = subject.asPublisher()
            .sink(receiveCompletion: { completion in
                if case let .failure(underlying) = completion {
                    receivedError = underlying as? TestError
                }
            },
            receiveValue: { received.append($0) })

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

        subscription = subject.asPublisher()
            .sink(receiveCompletion: { _ in },
            receiveValue: { received.append($0) })

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

        subscription = subject.asPublisher()
            .sink(receiveCompletion: { _ in },
            receiveValue: { received.append($0) })

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

        subscription = subject.asPublisher()
            .sink(receiveCompletion: { _ in },
            receiveValue: { received.append($0) })

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

        subscription = subject.asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { string, int in
                    received.append(("\(string): \(int)"))
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

        let subject = Observable.combineLatest(string, int)

        subscription = subject.asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { string, int in
                    received.append(("\(string ?? "<no title>"): \(int ?? 0)"))
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

        let subject = Observable.combineLatest(string, int)

        subscription = subject.asPublisher()
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    received.append("ERROR")
                }
            },
            receiveValue: { string, int in
                received.append(("\(string): \(int)"))
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

        let subject = Observable.combineLatest(string, int)

        subscription = subject.asPublisher()
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    received.append("ERROR")
                }
            },
            receiveValue: { _ in })

        int.on(.error(TestError.test))
        int.on(.next(1))

        XCTAssertEqual(received.count, 1)
        XCTAssertEqual(received.first, "ERROR")
    }

    func testCombineLatestDone_whenAllDone() {
        let obs1 = Observable<String>()
        let obs2 = Observable<Int>()

        var isDone = false
        subscription = Observable.combineLatest(obs1, obs2)
            .asPublisher()
            .sink(receiveCompletion: { completion in
                if case .finished = completion {
                    isDone = true
                }
            },
            receiveValue: { _ in })

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

        subscription = subject.asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { received.append($0) })

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
        subscription = subject.asPublisher()
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    exp.fulfill()
                }
            },
            receiveValue: { _ in })
        two.on(.error(TestError.test))
        waitForExpectations(timeout: 1)
    }

    func testCombineLatest3Error_fromThirdMember() {
        let one = Observable<String>()
        let two = Observable<Int>()
        let three = Observable<Double>()
        let subject = Observable.combineLatest(one, two, three)

        let exp = expectation(description: "combineLatest3 forwards error from observable")
        subscription = subject.asPublisher()
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    exp.fulfill()
                }
            },
            receiveValue: { _ in })
        three.on(.error(TestError.test))
        waitForExpectations(timeout: 1)
    }

    func testCombineLatest3Done_whenAllDone() {
        let obs1 = Observable<String>()
        let obs2 = Observable<Int>()
        let obs3 = Observable<Double>()

        var isDone = false
        subscription = Observable.combineLatest(obs1, obs2, obs3)
            .asPublisher()
            .sink(receiveCompletion: { completion in
                if case .finished = completion {
                    isDone = true
                }
            },
            receiveValue: { _ in })

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

        subscription = subject.asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { received.append($0) })

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

        subscription = subject.asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { received.append($0) })

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
        subscription = subject.asPublisher()
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    exp.fulfill()
                }
            },
            receiveValue: { _ in })
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
        subscription = subject.asPublisher()
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    exp.fulfill()
                }
            },
            receiveValue: { _ in })
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
        subscription = subject.asPublisher()
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    exp.fulfill()
                }
            },
            receiveValue: { _ in })
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
        subscription = subject.asPublisher()
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    exp.fulfill()
                }
            },
            receiveValue: { _ in })
        four.on(.error(TestError.test))
        waitForExpectations(timeout: 1)
    }

    func testCombineLatest4Done_whenAllDone() {
        let obs1 = Observable<String>()
        let obs2 = Observable<Int>()
        let obs3 = Observable<Double>()
        let obs4 = Observable<Float>()

        var isDone = false
        subscription = Observable.combineLatest(obs1, obs2, obs3, obs4)
            .asPublisher()
            .sink(receiveCompletion: { completion in
                if case .finished = completion {
                    isDone = true
                }
            },
            receiveValue: { _ in })

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

        subscription = subject.asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { received.append($0) })

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

        subscription = subject.asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { received.append($0) })

        observable.on(.next(1))
        observable.on(.next(10))

        XCTAssertEqual(received, ["Number: 1", "Number: 10"])
    }

    func testObservableMapError() {
        let observable = Observable<Int>()
        let subject = observable.map { "Number: \($0)" }

        let exp = expectation(description: "observable map forwards error")
        subscription = subject.asPublisher()
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    exp.fulfill()
                }
            },
            receiveValue: { _ in })

        observable.on(.error(TestError.test))

        waitForExpectations(timeout: 1)
    }

    func testObservableMapDone() {
        let observable = Observable<Int>()
        let subject = observable.map { "Number: \($0)" }

        let exp = expectation(description: "observable map forwards done")
        subscription = subject.asPublisher()
            .sink(receiveCompletion: { completion in
                if case .finished = completion {
                    exp.fulfill()
                }
            },
            receiveValue: { _ in })

        observable.on(.done)

        waitForExpectations(timeout: 1)
    }

    func testObservableFilter() {
        let observable = Observable<Int>()
        let subject = observable.filter { $0 % 2 == 0 }
        var received = [Int]()

        subscription = subject.asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { received.append($0) })

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
        subscription = subject.asPublisher()
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    exp.fulfill()
                }
            },
            receiveValue: { _ in })

        observable.on(.error(TestError.test))

        waitForExpectations(timeout: 1)
    }

    func testObservableFilterDone() {
        let observable = Observable<Int>()
        let subject = observable.filter { $0 % 2 == 0 }

        let exp = expectation(description: "observable filter forwards done")
        subscription = subject.asPublisher()
            .sink(receiveCompletion: { completion in
                if case .finished = completion {
                    exp.fulfill()
                }
            },
            receiveValue: { _ in })

        observable.on(.done)

        waitForExpectations(timeout: 1)
    }

    func testObservableFlatMap() {
        let fetchTrigger = Observable<Void>()
        let subject = fetchTrigger.flatMap { Variable(100).asObservable() }
        var received = [Int]()

        subscription = subject.asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { received.append($0) })
        fetchTrigger.on(.next(()))

        XCTAssertEqual(received, [100])
    }

    func testObservableFlatMapError() {
        let fetchTrigger = Observable<Void>()
        let subject = fetchTrigger.flatMap { Variable(100).asObservable() }

        let exp = expectation(description: "observable flatMap forwards error")
        subscription = subject.asPublisher()
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    exp.fulfill()
                }
            },
            receiveValue: { _ in })
        fetchTrigger.on(.error(TestError.test))

        waitForExpectations(timeout: 1)
    }

    func testObservableFlatMapDone() {
        let fetchTrigger = Observable<Void>()
        let subject = fetchTrigger.flatMap { Variable(100).asObservable() }

        let exp = expectation(description: "observable flatMap forwards done")
        subscription = subject.asPublisher()
            .sink(receiveCompletion: { completion in
                if case .finished = completion {
                    exp.fulfill()
                }
            },
            receiveValue: { _ in })
        fetchTrigger.on(.done)

        waitForExpectations(timeout: 1)
    }

    func testZipNonOptional() {
        var received: [String] = []

        let string = Observable<String>()
        let int = Observable<Int>()

        let subject = Observable.zip(string, int)

        subscription = subject.asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { string, int in
                    received.append("\(string): \(int)")
            })

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

        subscription = subject.asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { string, int in
                    received.append("\(string ?? "<no title>"): \(int ?? 0)")
            })

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

        subscription = subject.asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { string, int in
                    received.append("\(string): \(int)")
            })

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
        subscription = subject.asPublisher()
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    exp.fulfill()
                }
            },
            receiveValue: { _ in })
        one.on(.error(TestError.test))

        waitForExpectations(timeout: 1)
    }

    func testZipDone() {
        let one = Observable<String>()
        let two = Observable<Int>()

        var isDone = false
        subscription = Observable.zip(one, two)
            .asPublisher()
            .sink(receiveCompletion: { completion in
                if case .finished = completion {
                    isDone = true
                }
            },
            receiveValue: { _ in })

        one.on(.done)
        XCTAssertTrue(isDone)
    }
}
#endif
