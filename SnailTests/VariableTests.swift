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
        subject.value = nil
        subject.value = "1"
        subject.value = "2"
        XCTAssert(events[0] == nil)
        XCTAssert(events[1] == "1")
        XCTAssert(events[2] == "2")
        XCTAssert(subject.value == "2")
    }
}
