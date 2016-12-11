//  Copyright © 2016 Compass. All rights reserved.

import Foundation
import XCTest
@testable import Snail

class UIControlExtensionsTests: XCTestCase {
    private var subject: UIControl!

    override func setUp() {
        super.setUp()
        subject = UIControl()
    }

    func testControlEvent() {
        XCTAssertNotNil(subject.controlEvent(.touchUpInside))
    }
}
