//  Copyright © 2019 Compass. All rights reserved.

import XCTest

@testable import Snail

class DisposerTests: XCTestCase {

    private var subject: Disposer!
    private var observable: Observable<String>!

    override func setUp() {
        subject = Disposer()
        observable = Observable()
        observable.subscribe(onNext: { (_) in }).set(on: subject)
    }

    func testClean() {
        XCTAssertTrue(subject.disposables.count == 1)
        subject.clear()
        XCTAssertTrue(subject.disposables.count == 0)
    }
}
