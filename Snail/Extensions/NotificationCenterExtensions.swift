//  Copyright © 2016 Compass. All rights reserved.

import Foundation

extension NotificationCenter {
    private static var observableKey = "ObservableKey"

    @objc private func observableHandler(_ notification: Notification) {
        if let observable = objc_getAssociatedObject(self, &NotificationCenter.observableKey) as? Observable<Notification> {
            observable.on(.next(notification))
        }
    }

    public func observeEvent(_ name: Notification.Name?) -> Observable<Notification> {
        let observable = Observable<Notification>()
        objc_setAssociatedObject(self, &NotificationCenter.observableKey, observable, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        addObserver(self, selector: #selector(observableHandler(_:)), name: name, object: nil)
        return observable
    }
}
