//  Copyright © 2016 Compass. All rights reserved.

import UIKit
import XCTest
@testable import Snail

class NSNotificationCenterTests: XCTestCase {
    func testNotificaiton() {
        let exp = expectation(description: "notification")
        let notificationName = NSNotification.Name.UIKeyboardWillShow
        var notifcation: NSNotification?
        let subject = NotificationCenter.default.observeEvent(notificationName)
        subject.subscribe(onNext: { n in
            notifcation = n
            exp.fulfill()
        })
        NotificationCenter.default.post(name: notificationName, object: nil)
        waitForExpectations(timeout: 3) { error in
            XCTAssertNil(error)
            XCTAssertNotNil(notifcation)
            XCTAssert(notifcation?.name == notificationName)
        }
    }
}
