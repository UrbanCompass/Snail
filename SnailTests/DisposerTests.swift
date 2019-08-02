//  Copyright © 2019 Compass. All rights reserved.

import XCTest

@testable import Snail

class DisposerTests: XCTestCase {
    private var subject: Disposer!
    private var observable: Observable<String>!

    override func setUp() {
        super.setUp()
        subject = Disposer()
        observable = Observable()
        observable.subscribe(onNext: { (_) in }).add(to: subject)
    }

    func testClean() {
        XCTAssertTrue(subject.disposables.count == 1)
        subject.disposeAll()
        XCTAssertTrue(subject.disposables.count == 0)
    }
}
