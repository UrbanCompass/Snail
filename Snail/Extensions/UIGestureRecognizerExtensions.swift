//  Copyright © 2016 Compass. All rights reserved.

#if os(iOS) || os(tvOS)
import UIKit

extension UIGestureRecognizer {
    private static var observableKey = "com.compass.Snail.UIGestureRecognizer.ObservableKey"

    public func asObservable() -> Observable<(UIGestureRecognizer, UIEvent)> {
        if let observable = objc_getAssociatedObject(self, &UIGestureRecognizer.observableKey) as? Observable<(UIGestureRecognizer, UIEvent)> {
            return observable
        }
        let observable = Observable<(UIGestureRecognizer, UIEvent)>()
        objc_setAssociatedObject(self, &UIGestureRecognizer.observableKey, observable, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        addTarget(self, action: #selector(observableHandler))
        return observable
    }

    @objc private func observableHandler(sender: UIGestureRecognizer, event: UIEvent) {
        if let observable = objc_getAssociatedObject(self, &UIGestureRecognizer.observableKey) as? Observable<(UIGestureRecognizer, UIEvent)> {
            observable.on(.next((sender, event)))
        }
    }
}

#endif
