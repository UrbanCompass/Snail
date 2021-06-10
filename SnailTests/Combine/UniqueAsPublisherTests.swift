//  Copyright © 2021 Compass. All rights reserved.

import Combine
import Foundation
@testable import Snail
import XCTest

@available(iOS 13.0, *)
class UniqueAsPublisherTests: XCTestCase {
    private var subscriptions: Set<AnyCancellable>!

    override func setUp() {
        subscriptions = Set<AnyCancellable>()
    }

    override func tearDown() {
        subscriptions = nil
    }

    func testVariableChanges() {
        var events: [String?] = []
        let subject = Unique<String?>(nil)
        subject.asObservable()
            .asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { events.append($0) })
            .store(in: &subscriptions)

        subject.value = nil
        subject.value = "1"
        subject.value = "2"
        subject.value = "2"
        subject.value = "2"
        XCTAssertEqual(events[0], nil)
        XCTAssertEqual(events[1], "1")
        XCTAssertEqual(events[2], "2")
        XCTAssertEqual(subject.value, "2")
        XCTAssertEqual(events.count, 3)
    }

    func testVariableNotifiesOnSubscribe() {
        let subject = Unique("initial")
        subject.value = "new"
        var result: String?

        subject.asObservable()
            .asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { result = $0 })
            .store(in: &subscriptions)

        XCTAssertEqual("new", result)
    }

    func testVariableNotifiesInitialOnSubscribe() {
        let subject = Unique("initial")
        var result: String?

        subject.asObservable()
            .asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { result = $0 })
            .store(in: &subscriptions)

        XCTAssertEqual("initial", result)
    }

    func testVariableHandlesEquatableArrays() {
        var events: [[String]] = []
        let subject = Unique<[String]>(["1", "2"])
        subject.asObservable()
            .asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { events.append($0) })
            .store(in: &subscriptions)

        subject.value = ["1", "2"]
        subject.value = ["2", "1"]
        subject.value = ["2", "1"]
        subject.value = ["1", "2"]
        XCTAssertEqual(events[0], ["1", "2"])
        XCTAssertEqual(events[1], ["2", "1"])
        XCTAssertEqual(events[2], ["1", "2"])
    }

    func testVariableHandlesOptionalArrays() {
        var events: [[String]?] = []
        let subject = Unique<[String]?>(nil)
        subject.asObservable()
            .asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { events.append($0) })
            .store(in: &subscriptions)
        subject.value = ["1", "2"]
        subject.value = nil
        subject.value = nil
        subject.value = ["1", "2"]
        XCTAssertEqual(events[0], nil)
        XCTAssertEqual(events[1], ["1", "2"])
        XCTAssertEqual(events[2], nil)
        XCTAssertEqual(events[3], ["1", "2"])
    }
}
