//  Copyright © 2016 Compass. All rights reserved.

import Foundation

extension NotificationCenter {
    public func observeEvent(_ name: Notification.Name?, object: AnyObject? = nil) -> Observable<Notification> {
        let observable = Observable<Notification>()
        addObserver(forName: name, object: object, queue: nil) { notification in
            observable.on(.next(notification))
        }
        return observable
    }
}
