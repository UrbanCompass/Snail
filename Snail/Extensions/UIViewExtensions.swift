//  Copyright © 2016 Compass. All rights reserved.

import Foundation

extension UIView {
    private static var observableKey = "ObservableKey"

    public var tap: Observable<Void> {
        get {
            let observable = Observable<Void>()
            objc_setAssociatedObject(self, &UIView.observableKey, observable, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            let tap = UITapGestureRecognizer(target: self, action: #selector(observableHandler))
            addGestureRecognizer(tap)
            return observable
        }
    }

    func observableHandler() {
        if let observable = objc_getAssociatedObject(self, &UIView.observableKey) as? Observable<Void> {
            observable.on(.next())
        }
    }
}
