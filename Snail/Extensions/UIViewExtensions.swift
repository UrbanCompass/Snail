//  Copyright © 2016 Compass. All rights reserved.

#if os(iOS) || os(tvOS)
import UIKit

public extension UIView {
    public func observe(event: Notification.Name) -> Observable<Notification> {
        return NotificationCenter.default.observeEvent(event)
    }

    public var tap: Observable<Void> {
        if let control = self as? UIControl {
            return control.controlEvent(.touchUpInside)
        }
        let tap = UITapGestureRecognizer()
        addGestureRecognizer(tap)
        let result = Observable<Void>()
        tap.asObservable().subscribe(onNext: { _ in result.on(.next(())) })
        return result
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
