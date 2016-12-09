//
//  ControlEvent.swift
//  Snail
//
//  Created by Wes Billman on 12/9/16.
//  Copyright © 2016 Compass. All rights reserved.
//

import Foundation

public class ControlEvent: NSObject {
    let selector: Selector = #selector(ControlEvent.eventHandler(_:))

    weak var control: UIControl?
    let controlEvents: UIControlEvents
    let observable: Observable<Void>

    func eventHandler(_ sender: UIControl!) {
        observable.on(.next())
    }

    public init(control: UIControl, controlEvents: UIControlEvents) {
        self.control = control
        self.controlEvents = controlEvents
        self.observable = Observable<Void>()
        super.init()

        control.addTarget(self, action: selector, for: controlEvents)

        let method = self.method(for: selector)
        if method == nil {
            fatalError("Can't find method")
        }
    }

    public func asObservable() -> Observable<Void> {
        return observable
    }
}
