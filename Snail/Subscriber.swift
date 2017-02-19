//  Copyright © 2017 Compass. All rights reserved.

import Foundation

struct Subscriber<T> {
    let queue: DispatchQueue?
    let handler: (Event<T>) -> Void
}
