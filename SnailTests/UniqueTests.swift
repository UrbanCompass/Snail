//  Copyright © 2017 Compass. All rights reserved.

import Foundation
import XCTest
@testable import Snail

class UniqueTests: XCTestCase {
    private let disposer = Disposer()

    func testVariableChanges() {
        var events: [String?] = []
        let subject = Unique<String?>(nil)
        subject.asObservable().subscribe(
            onNext: { string in events.append(string) }
        ).add(to: disposer)
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

        subject.asObservable().subscribe(onNext: { result = $0 }).add(to: disposer)

        XCTAssertEqual("new", result)
    }

    func testVariableNotifiesInitialOnSubscribe() {
        let subject = Unique("initial")
        var result: String?

        subject.asObservable().subscribe(onNext: { result = $0 }).add(to: disposer)

        XCTAssertEqual("initial", result)
    }

    func testVariableHandlesEquatableArrays() {
        var events: [[String]] = []
        let subject = Unique<[String]>(["1", "2"])
        subject.asObservable().subscribe(onNext: { array in events.append(array) }).add(to: disposer)

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
        subject.asObservable().subscribe(
            onNext: { array in events.append(array) }
        ).add(to: disposer)
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
