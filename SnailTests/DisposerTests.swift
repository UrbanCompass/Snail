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

    func testDisposeOnDeinitRemovesSubscribers() {
        var subject: Disposer? = Disposer()
        let exp = expectation(description: "test")
        var sum = 0

        let obs = Observable<Void>()
        for _ in 0..<10 {
            if subject == nil {
                subject = Disposer()
            }
            obs.subscribe(onNext: {
                sum += 1
            }).add(to: subject!)

        }
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.5) {
            subject = nil
            obs.on(.next(()))
            XCTAssertEqual(sum, 0)
            exp.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
}
