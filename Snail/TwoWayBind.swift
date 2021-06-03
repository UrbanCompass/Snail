//  Copyright © 2021 Compass. All rights reserved.

import Foundation

protocol TwoWayBind {
    associatedtype BindableType
    func twoWayBind(with: BindableType)
}
