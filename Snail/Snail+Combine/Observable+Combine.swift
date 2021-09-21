//  Copyright © 2021 Compass. All rights reserved.

import Combine
import Foundation

@available(iOS 13.0, *)
public extension ObservableType {
    func asAnyPublisher() -> AnyPublisher<T, Error> {
        return SnailPublisher(upstream: self).eraseToAnyPublisher()
    }
}
