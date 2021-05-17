//  Copyright © 2021 Compass. All rights reserved.

import Combine
import Foundation
@testable import Snail
import XCTest

@available(iOS 13.0, *)
class VariableAsPublisherTests: XCTestCase {
    private var subscription: AnyCancellable?

    override func tearDown() {
        subscription = nil
    }

    func testVariableChanges() {
        var events: [String?] = []
        let subject = Variable<String?>(nil)
        subscription = subject.asObservable()
            .asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { events.append($0) })
        subject.value = "1"
        subject.value = "2"
        XCTAssertEqual(events[0], nil)
        XCTAssertEqual(events[1], "1")
        XCTAssertEqual(events[2], "2")
        XCTAssertEqual(subject.value, "2")
    }

    func testVariableNotifiesOnSubscribe() {
        let subject = Variable("initial")
        subject.value = "new"
        var result: String?

        subscription = subject.asObservable()
            .asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { result = $0 })

        XCTAssertEqual("new", result)
    }

    func testVariableNotifiesInitialOnSubscribe() {
        let subject = Variable("initial")
        var result: String?

        subscription = subject.asObservable()
            .asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { result = $0 })

        XCTAssertEqual("initial", result)
    }

    func testMappedVariableNotifiesOnSubscribe() {
        let subject = Variable("initial")
        subject.value = "new"
        var subjectCharactersCount: Int?

        subscription = subject.asObservable()
            .asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { subjectCharactersCount = $0.count })

        XCTAssertEqual(subject.value.count, subjectCharactersCount)
    }

    func testMappedVariableNotifiesInitialOnSubscribe() {
        let subject = Variable("initial")
        var subjectCharactersCount: Int?

        subscription = subject.asObservable()
            .asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { subjectCharactersCount = $0.count })

        XCTAssertEqual(subject.value.count, subjectCharactersCount)
    }

    func testUniqueFireCounts() {
        let subject = Unique("sameValue")
        var firedCount = 0

        subscription = subject.asObservable()
            .asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { _ in firedCount += 1 })

        subject.value = "sameValue"

        XCTAssertEqual(firedCount, 1)
    }

    func testVariableFireCounts() {
        let subject = Variable("sameValue")
        var firedCount = 0

        subscription = subject.asObservable()
            .asPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { _ in firedCount += 1 })

        subject.value = "sameValue"

        XCTAssertEqual(firedCount, 2)
    }
}
