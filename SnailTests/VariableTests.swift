//  Copyright © 2016 Compass. All rights reserved.

import Foundation
import XCTest
@testable import Snail

class VariableTests: XCTestCase {
    func testVariableChanges() {
        var events: [String?] = []
        let subject = Variable<String?>(nil)
        subject.asObservable().subscribe(
            onNext: { string in events.append(string) }
        )
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

        subject.asObservable().subscribe(onNext: { result = $0 })

        XCTAssertEqual("new", result)
    }

    func testVariableNotifiesInitialOnSubscribe() {
        let subject = Variable("initial")
        var result: String?

        subject.asObservable().subscribe(onNext: { result = $0 })

        XCTAssertEqual("initial", result)
    }

    func testMappedVariableNotifiesOnSubscribe() {
        let subject = Variable("initial")
        subject.value = "new"
        var subjectCharactersCount: Int?

        subject.map { $0.count }.asObservable().subscribe(onNext: { subjectCharactersCount = $0 })

        XCTAssertEqual(subject.value.count, subjectCharactersCount)
    }

    func testMappedVariableNotifiesInitialOnSubscribe() {
        let subject = Variable("initial")
        var subjectCharactersCount: Int?

        subject.map { $0.count }.asObservable().subscribe(onNext: { subjectCharactersCount = $0 })

        XCTAssertEqual(subject.value.count, subjectCharactersCount)
    }

    func testUniqueFireCounts() {
        let subject = Unique("one")
        var firedCount = 0

        subject.map { $0.count }.asObservable().subscribe(onNext: { _ in
            firedCount += 1
        })

        subject.value = "two"

        XCTAssertTrue(firedCount == 1)
    }

    func testVariableFireCounts() {
        let subject = Variable("one")
        var firedCount = 0

        subject.map { $0.count }.asObservable().subscribe(onNext: { _ in
            firedCount += 1
        })

        subject.value = "two"

        XCTAssertEqual(firedCount, 2)
    }

    func testMapToVoid() {
        let subject = Variable("initial")
        var fired = false

        subject.map { _ in return () }.asObservable().subscribe(onNext: { _ in
            fired = true
        })

        XCTAssertTrue(fired)
    }

    func testBindToOtherVariable() {
        let subject = Variable("one")
        let observedVariable = Variable("two")

        subject.bind(to: observedVariable)
        XCTAssertEqual(subject.value, "two")

        observedVariable.value = "three"
        XCTAssertEqual(subject.value, "three")
    }
}
