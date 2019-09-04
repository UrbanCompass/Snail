//  Copyright © 2016 Compass. All rights reserved.

import Foundation
import XCTest
@testable import Snail

class ClosureTests: XCTestCase {
    func testClosure() {
        let expectation = self.expectation(description: "Closure Executed")
        let disposer = Disposer()
        let closure = Closure {
            expectation.fulfill()
        }.add(to: disposer)

        closure.closure?()

        waitForExpectations(timeout: 0.1, handler: nil)
        disposer.disposeAll()
        XCTAssertNil(closure.closure)
    }
}
