//  Copyright © 2016 Compass. All rights reserved.

import Foundation
import XCTest
@testable import Snail

class UIButtonExtensionsTests: XCTestCase {
    private var subject: UIButton!

    override func setUp() {
        super.setUp()
        subject = UIButton()
    }

    func testTap() {
        XCTAssertNotNil(subject.tap)
    }
}
