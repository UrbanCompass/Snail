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
        XCTAssert(events[0] == nil)
        XCTAssert(events[1] == "1")
        XCTAssert(events[2] == "2")
        XCTAssert(subject.value == "2")
    }

    func testVariableNotifiesOnSubscribe() {
        let subject = Variable("initial")
        subject.value = "new"
        var result: String?

        subject.asObservable().subscribe(onNext: { string in
            result = string
        })

        XCTAssertEqual("new", result)
    }

    func testVariableNotifiesInitialOnSubscribe() {
        let subject = Variable("initial")
        var result: String?

        subject.asObservable().subscribe(onNext: { string in
            result = string
        })

        XCTAssertEqual("initial", result)
    }
}
