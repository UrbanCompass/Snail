//  Copyright © 2021 Compass. All rights reserved.

import Foundation

protocol TwoWayBind {
    associatedtype T
    func twoWayBind(with: Variable<T>)
}
