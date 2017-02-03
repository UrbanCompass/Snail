//  Copyright © 2016 Compass. All rights reserved.

import Foundation

public enum Event<T> {
    case next(T)
    case error(Error)
    case done
}
