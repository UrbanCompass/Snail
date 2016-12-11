//  Copyright © 2016 Compass. All rights reserved.

import Foundation
import XCTest
@testable import Snail

class ControlEventTests: XCTestCase {
    private var subject: ControlEvent!
    private var control: UIControl!

    override func setUp() {
        super.setUp()
        subject = ControlEvent(control: UIControl(), controlEvents: .touchUpInside)
    }

    func testEventHandlerOnNext() {
        var gotEvent = false
        subject.asObservable().subscribe(onNext: {
            gotEvent = true
        })

        subject.eventHandler(control)
        XCTAssert(gotEvent)
    }
}
