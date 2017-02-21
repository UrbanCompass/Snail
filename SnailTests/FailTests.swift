//  Copyright © 2016 Compass. All rights reserved.

import Foundation
import XCTest
@testable import Snail

class FailTests: XCTestCase {
    enum TestError: Error {
        case test
    }

    private var subject: Observable<String>?
    private var strings: [String]?
    private var error: Error?
    private var done: Bool?

    override func setUp() {
        super.setUp()
        subject = Fail(TestError.test)
        strings = []
        subject?.subscribe(onNext: { [weak self] string in self?.strings?.append(string) })
    }

    func testFail() {
        subject?
            .subscribe(onError: { error in self.error = error })
        subject?.on(.next("1"))
        XCTAssert(strings?.count == 0)
        XCTAssert((error as? TestError) == TestError.test)
    }
}
