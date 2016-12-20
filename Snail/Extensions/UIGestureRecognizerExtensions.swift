//  Copyright © 2016 Compass. All rights reserved.

import UIKit

extension UIGestureRecognizer {
    private static var observableKey = "ObservableKey"

    public func asObservable() -> Observable<Void> {
        let observable = Observable<Void>()
        objc_setAssociatedObject(self, &UIGestureRecognizer.observableKey, observable, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        addTarget(self, action: #selector(observableHandler))
        return observable
    }

    func observableHandler() {
        if let observable = objc_getAssociatedObject(self, &UIGestureRecognizer.observableKey) as? Observable<Void> {
            observable.on(.next())
        }
    }
}
