//  Copyright © 2017 Compass. All rights reserved.

import Foundation
import XCTest
@testable import Snail

class UniqueVariableTests: XCTestCase {
    func testVariableChanges() {
        var events: [String?] = []
        let subject = UniqueVariable<String>(nil)
        subject.asObservable().subscribe(
            onNext: { string in events.append(string) }
        )
        subject.value = nil
        subject.value = "1"
        subject.value = "2"
        subject.value = "2"
        subject.value = "2"
        XCTAssert(events[0] == "1")
        XCTAssert(events[1] == "2")
        XCTAssert(subject.value == "2")
        XCTAssert(events.count == 2)
    }

    func testVariableNotifiesOnSubscribe() {
        let subject = UniqueVariable("initial")
        subject.value = "new"
        var result: String?

        subject.asObservable().subscribe(onNext: { string in
            result = string
        })

        XCTAssertEqual("new", result)
    }

    func testVariableNotifiesInitialOnSubscribe() {
        let subject = UniqueVariable<String>(nil)
        var result: String?

        subject.asObservable().subscribe(onNext: { string in
            result = string
        })

        XCTAssertEqual(nil, result)
    }
}
