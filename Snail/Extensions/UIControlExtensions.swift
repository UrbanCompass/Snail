//  Copyright © 2016 Compass. All rights reserved.

public extension UIControl {
    private static var observableKey = "ObservableKey"

    public func controlEvent(_ controlEvents: UIControlEvents) -> Observable<Void> {
        let observable = Observable<Void>()
        objc_setAssociatedObject(self, &UIControl.observableKey, observable, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        addTarget(self, action: #selector(observableHandler(_:)), for: controlEvents)
        return observable
    }

    func observableHandler(_ sender: UIControl) {
        if let observable = objc_getAssociatedObject(self, &UIControl.observableKey) as? Observable<Void> {
            DispatchQueue.main.async {
                observable.on(.next())
            }
        }
    }
}
