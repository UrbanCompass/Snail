//  Copyright © 2016 Compass. All rights reserved.

#if os(iOS) || os(tvOS)
import UIKit

public extension UIView {
    public func observe(event: Notification.Name) -> Observable<Notification> {
        var key = event
        return associatedNotification(name: event, key: &key)
    }

    private func associatedNotification(name: Notification.Name, key: UnsafeRawPointer) -> Observable<Notification> {
        if let observable = objc_getAssociatedObject(self, key) as? Observable<Notification> {
            return observable
        }
        let observable = Observable<Notification>()
        NotificationCenter.default.observeEvent(name).subscribe(onNext: { observable.on(.next($0)) })
        objc_setAssociatedObject(self, key, observable, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return observable
    }

    public var tap: Observable<Void> {
        if let control = self as? UIControl {
            return control.controlEvent(.touchUpInside)
        }
        let tap = UITapGestureRecognizer()
        addGestureRecognizer(tap)
        return tap.asObservable()
    }
}

#endif
