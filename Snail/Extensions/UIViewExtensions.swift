//  Copyright © 2016 Compass. All rights reserved.

#if os(iOS) || os(tvOS)
import UIKit

public extension UIView {
    private static var observableKey = "com.compass.Snail.UIView.ObservableKey"
    private static var disposerKey = "com.compass.Snail.UIView.Disposer"

    func observe(event: Notification.Name) -> Observable<Notification> {
        return NotificationCenter.default.observeEvent(event)
    }

    private var tapObservable: Observable<Void> {
        if let observable = objc_getAssociatedObject(self, &UIView.observableKey) as? Observable<Void> {
            return observable
        }
        let observable = Observable<Void>()
        objc_setAssociatedObject(self, &UIView.observableKey, observable, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        let tap = UITapGestureRecognizer()
        addGestureRecognizer(tap)
        tap.asObservable().subscribe(onNext: { [weak observable] _ in observable?.on(.next(())) })
            .add(to: disposer)

        return observable
    }

    var tap: Observable<Void> {
        if let control = self as? UIControl {
            return control.controlEvent(.touchUpInside)
        }
        return tapObservable
    }

    var keyboardHeightWillChange: Observable<(height: CGFloat, duration: Double)> {
        let observable = Observable<(height: CGFloat, duration: Double)>()
        observe(event: UIResponder.keyboardWillShowNotification).subscribe(onNext: { notification in
            guard let offset = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
                let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
                    return
            }
            observable.on(.next((offset.cgRectValue.size.height, duration)))
        }).add(to: disposer)

        observe(event: UIResponder.keyboardWillHideNotification).subscribe(onNext: { notification in
            guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
                return
            }
            observable.on(.next((0, duration)))
        }).add(to: disposer)
        return observable
    }

    var disposer: Disposer {
        if let disposer = objc_getAssociatedObject(self, &UIView.disposerKey) as? Disposer {
            return disposer
        }
        let disposer = Disposer()
        objc_setAssociatedObject(self, &UIView.disposerKey, disposer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return disposer
    }
}

#endif
