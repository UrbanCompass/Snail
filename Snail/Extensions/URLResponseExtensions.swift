//  Copyright © 2017 Compass. All rights reserved.

import Foundation

extension URLResponse {
    public var isSuccessful: Bool {
        guard let response = self as? HTTPURLResponse else {
            return false
        }
        return (200...299 ~= response.statusCode)
    }
}
