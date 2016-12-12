//  Copyright © 2016 Compass. All rights reserved.

import Foundation
import XCTest
@testable import Snail

class JustTests: XCTestCase {

    func testJust() {
        var result: Int?
        let subject = Just<Int>(1)
        subject.subscribe(
            onNext: { value in result = value}
        )
        XCTAssertEqual(1, result)

    }
}
