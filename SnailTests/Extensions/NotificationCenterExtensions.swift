//  Copyright © 2016 Compass. All rights reserved.

import UIKit
import XCTest
@testable import Snail

class NotificationCenterTests: XCTestCase {
    func testNotificaiton() {
        let exp = expectation(description: "notification")
        let notificationName = Notification.Name.UIKeyboardWillShow
        var notifcation: Notification?
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
