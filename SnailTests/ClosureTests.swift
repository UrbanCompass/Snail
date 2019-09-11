//  Copyright © 2016 Compass. All rights reserved.

import Foundation
import XCTest
@testable import Snail

class ClosureTests: XCTestCase {
    func testClosure() {
        let disposer = Disposer()
        var closureFired = false

        let closure = Closure {
            closureFired = true
        }.add(to: disposer)

        closure.closure?()

        XCTAssertEqual(closureFired, true)
        disposer.disposeAll()
        XCTAssertNil(closure.closure)
    }
}
