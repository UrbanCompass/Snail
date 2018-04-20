//  Copyright © 2016 Compass. All rights reserved.

#if os(iOS) || os(tvOS)
import UIKit

extension UIGestureRecognizer {
    private static var observableKey = "ObservableKey"

    public func asObservable() -> Observable<UIGestureRecognizerState> {
        if let observable = objc_getAssociatedObject(self, &UIGestureRecognizer.observableKey) as? Observable<UIGestureRecognizerState> {
            return observable
        }
        let observable = Observable<UIGestureRecognizerState>()
        objc_setAssociatedObject(self, &UIGestureRecognizer.observableKey, observable, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        addTarget(self, action: #selector(observableHandler))
        return observable
    }

    @objc private func observableHandler() {
        if let observable = objc_getAssociatedObject(self, &UIGestureRecognizer.observableKey) as? Observable<UIGestureRecognizerState> {
            observable.on(.next(state))
        }
    }
}

#endif
