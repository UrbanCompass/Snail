//  Copyright © 2016 Compass. All rights reserved.

import Foundation
import XCTest
@testable import Snail

class ClosureTests: XCTestCase {
    func testClosure() {
        let expectation = self.expectation(description: "Closure Executed")

        let closure = Closure {
            expectation.fulfill()
        }

        closure.closure?()

        waitForExpectations(timeout: 5, handler: nil)
        closure.dispose()
        XCTAssertNil(closure.closure)
    }
}
