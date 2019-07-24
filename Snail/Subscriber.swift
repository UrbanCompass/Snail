//  Copyright © 2017 Compass. All rights reserved.

import Foundation

public class Subscriber<T> {
    let queue: DispatchQueue?
    let handler: (Event<T>) -> Void

    public init(queue: DispatchQueue?, handler: @escaping (Event<T>) -> Void) {
        self.queue = queue
        self.handler = handler
    }
}
