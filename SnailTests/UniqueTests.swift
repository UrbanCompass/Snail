//  Copyright © 2017 Compass. All rights reserved.

import Foundation
import XCTest
@testable import Snail

class UniqueTests: XCTestCase {
    func testVariableChanges() {
        var events: [String?] = []
        let subject = Unique<String?>(nil)
        subject.asObservable().subscribe(
            onNext: { string in events.append(string) }
        )
        subject.value = nil
        subject.value = "1"
        subject.value = "2"
        subject.value = "2"
        subject.value = "2"
        XCTAssert(events[0] == nil)
        XCTAssert(events[1] == "1")
        XCTAssert(events[2] == "2")
        XCTAssert(subject.value == "2")
        XCTAssert(events.count == 3)
    }

    func testVariableNotifiesOnSubscribe() {
        let subject = Unique("initial")
        subject.value = "new"
        var result: String?

        subject.asObservable().subscribe(onNext: { string in
            result = string
        })

        XCTAssertEqual("new", result)
    }

    func testVariableNotifiesInitialOnSubscribe() {
        let subject = Unique<String?>("initial")
        var result: String?

        subject.asObservable().subscribe(onNext: { string in
            result = string
        })

        XCTAssertEqual("initial", result)
    }

    func testVariableHandlesEquatableArrays() {
        var events: [[String]] = []
        let subject = Unique<[String]>(["1", "2"])
        subject.asObservable().subscribe(
            onNext: { array in events.append(array) }
        )
        subject.value = ["1", "2"]
        subject.value = ["2", "1"]
        subject.value = ["2", "1"]
        subject.value = ["1", "2"]
        XCTAssert(events[0] == ["1", "2"])
        XCTAssert(events[1] == ["2", "1"])
        XCTAssert(events[2] == ["1", "2"])
    }

    func testVariableHandlesOptionalArrays() {
        var events: [[String]?] = []
        let subject = Unique<[String]?>(nil)
        subject.asObservable().subscribe(
            onNext: { array in events.append(array) }
        )
        subject.value = ["1", "2"]
        subject.value = nil
        subject.value = nil
        subject.value = ["1", "2"]
        XCTAssert(events[0] == nil)
        XCTAssert(events[1] == ["1", "2"])
        XCTAssert(events[2] == nil)
        XCTAssert(events[3] == ["1", "2"])
    }
}
