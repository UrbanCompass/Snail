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

        subject.asObservable().subscribe(onNext: { result = $0 })

        XCTAssertEqual("new", result)
    }

    func testVariableNotifiesInitialOnSubscribe() {
        let subject = Unique("initial")
        var result: String?

        subject.asObservable().subscribe(onNext: { result = $0 })

        XCTAssertEqual("initial", result)
    }

    func testMappedVariableNotifiesOnSubscribe() {
        let subject = Unique("initial")
        subject.value = "new"
        var subjectCharactersCount: Int?

        subject.map { $0.count }.asObservable().subscribe(onNext: { count in
            subjectCharactersCount = count
        })

        XCTAssertEqual(subject.value.count, subjectCharactersCount)
    }

    func testMappedVariableNotifiesInitialOnSubscribe() {
        let subject = Unique("initial")
        var subjectCharactersCount: Int?

        subject.map { $0.count }.asObservable().subscribe(onNext: { subjectCharactersCount = $0 })

        XCTAssertEqual(subject.value.count, subjectCharactersCount)
    }

    func testVariableHandlesEquatableArrays() {
        var events: [[String]] = []
        let subject = Unique<[String]>(["1", "2"])
        subject.asObservable().subscribe(onNext: { array in events.append(array) })

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
        )
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
