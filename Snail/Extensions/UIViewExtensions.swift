//  Copyright © 2016 Compass. All rights reserved.

#if os(iOS) || os(tvOS)
import UIKit

public extension UIView {
    private static var observableKey = "com.compass.Snail.UIView.ObservableKey"

    public func observe(event: Notification.Name) -> Observable<Notification> {
        return NotificationCenter.default.observeEvent(event)
    }

    private var tapObservable: Observable<Void> {
        if let observable = objc_getAssociatedObject(self, &UIView.observableKey) as? Observable<Void> {
            return observable
        }
        let observable = Observable<Void>()
        objc_setAssociatedObject(self, &UIView.observableKey, observable, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return observable
    }

    public var tap: Observable<Void> {
        if let control = self as? UIControl {
            return control.controlEvent(.touchUpInside)
        }
        let tap = UITapGestureRecognizer()
        addGestureRecognizer(tap)
        tap.asObservable().subscribe(onNext: { [weak self] _ in self?.tapObservable.on(.next(())) })
        return tapObservable
    }

    public var keyboardHeightWillChange: Observable<(height: CGFloat, duration: Double)> {
        let observable = Observable<(height: CGFloat, duration: Double)>()
        observe(event: .UIKeyboardWillShow).subscribe(onNext: { notification in
            guard let offset = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue,
                let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double else {
                    return
            }
            observable.on(.next((offset.cgRectValue.size.height, duration)))
        })

        observe(event: .UIKeyboardWillHide).subscribe(onNext: { notification in
            guard let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double else {
                return
            }
            observable.on(.next((0, duration)))
        })
        return observable
    }
}

#endif
