//  Copyright © 2016 Compass. All rights reserved.

import UIKit
import XCTest
@testable import Snail

class NotificationCenterTests: XCTestCase {
    func testNotification() {
        let exp = expectation(description: "notification")
        let notificationName = Notification.Name.UIKeyboardWillShow
        var notifcation: Notification?
        let subject = NotificationCenter.default.observeEvent(notificationName)
        subject.subscribe(onNext: { notification in
            notifcation = notification
            exp.fulfill()
        })
        NotificationCenter.default.post(name: notificationName, object: nil)
        waitForExpectations(timeout: 3) { error in
            XCTAssertNil(error)
            XCTAssertNotNil(notifcation)
            XCTAssert(notifcation?.name == notificationName)
        }
    }

    func testMultipleNotifications() {
        let willHide = expectation(description: "notification")
        var gotWillShow = false
        var gotWillHide = false

        let willShowName = Notification.Name.UIKeyboardWillShow
        let willHideName = Notification.Name.UIKeyboardWillHide

        NotificationCenter.default.observeEvent(willShowName).subscribe(onNext: { _ in gotWillShow = true })
        NotificationCenter.default.observeEvent(willHideName).subscribe(onNext: { _ in
            gotWillHide = true
            willHide.fulfill()
        })

        NotificationCenter.default.post(name: willShowName, object: nil)
        NotificationCenter.default.post(name: willHideName, object: nil)

        waitForExpectations(timeout: 3) { error in
            XCTAssertNil(error)
            XCTAssert(gotWillShow)
            XCTAssert(gotWillHide)
        }
    }
}
