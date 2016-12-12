//  Copyright © 2016 Compass. All rights reserved.

import Foundation
import XCTest
@testable import Snail

class JustTests: XCTestCase {
    func testJustOnNext() {
        var result: Int?
        let subject = Just(1)
        subject.subscribe(
            onNext: { value in result = value}
        )
        XCTAssertEqual(1, result)
    }

    func testJustEvent() {
        var result: Int?
        let subject = Just(1)
        subject.subscribe { event in
            if case .next(let value) = event {
                result = value
            }
        }
        XCTAssertEqual(1, result)
    }
}
