//  Copyright © 2016 Compass. All rights reserved.

#if os(iOS) || os(tvOS)
import UIKit

extension UIBarButtonItem {
    private static var observableKey = "ObservableKey"

    public var tap: Observable<Void> {
        if let observable = objc_getAssociatedObject(self, &UIBarButtonItem.observableKey) as? Observable<Void> {
            return observable
        }
        let observable = Observable<Void>()
        objc_setAssociatedObject(self, &UIBarButtonItem.observableKey, observable, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        target = self
        action = #selector(observableHandler(_:))
        return observable
    }

    @objc private func observableHandler(_ sender: UIBarButtonItem) {
        if let observable = objc_getAssociatedObject(self, &UIBarButtonItem.observableKey) as? Observable<Void> {
            observable.on(.next(()))
        }
    }
}

#endif
