//  Copyright © 2016 Compass. All rights reserved.

#if os(iOS) || os(tvOS)
import UIKit

extension UIGestureRecognizer {
    private static var observableKey = "com.compass.Snail.UIGestureRecognizer.ObservableKey"

    public func asObservable() -> Observable<UIGestureRecognizer.State> {
        if let observable = objc_getAssociatedObject(self, &UIGestureRecognizer.observableKey) as? Observable<UIGestureRecognizer.State> {
            return observable
        }
        let observable = Observable<UIGestureRecognizer.State>()
        objc_setAssociatedObject(self, &UIGestureRecognizer.observableKey, observable, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        addTarget(self, action: #selector(observableHandler))
        return observable
    }

    @objc private func observableHandler() {
        if let observable = objc_getAssociatedObject(self, &UIGestureRecognizer.observableKey) as? Observable<UIGestureRecognizer.State> {
            observable.on(.next(state))
        }
    }
}

#endif
