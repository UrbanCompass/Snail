//  Copyright © 2016 Compass. All rights reserved.

#if os(iOS) || os(tvOS)
import UIKit

public extension UIView {
    private static var keyboardWillShowObservableKey = "UIKeyboardWillShowObservableKey"
    private static var keyboardWillHideObservableKey = "UIKeyboardWillHideObservableKey"

    public var keyboardWillShow: Observable<Notification> {
        return associatedNotification(name: Notification.Name.UIKeyboardWillShow, key: &UIView.keyboardWillShowObservableKey)
    }

    public var keyboardWillHide: Observable<Notification> {
        return associatedNotification(name: Notification.Name.UIKeyboardWillHide, key: &UIView.keyboardWillHideObservableKey)
    }

    public var tap: Observable<Void> {
        if let control = self as? UIControl {
            return control.controlEvent(.touchUpInside)
        }
        let tap = UITapGestureRecognizer()
        addGestureRecognizer(tap)
        return tap.asObservable()
    }

    private func associatedNotification(name: NSNotification.Name, key: UnsafeRawPointer) -> Observable<Notification> {
        if let observable = objc_getAssociatedObject(self, key) as? Observable<Notification> {
            return observable
        }
        let observable = Observable<Notification>()
        NotificationCenter.default.observeEvent(name).subscribe(onNext: { observable.on(.next($0)) })
        objc_setAssociatedObject(self, key, observable, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return observable
    }
}

#endif
