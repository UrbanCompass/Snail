//  Copyright © 2016 Compass. All rights reserved.

public enum Event<T> {
    case next(T)
    case error(Error)
    case done
}
