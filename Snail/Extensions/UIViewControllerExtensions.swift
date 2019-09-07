//  Copyright © 2016 Compass. All rights reserved.

#if os(iOS) || os(tvOS)
import UIKit
#else
import Foundation
#endif

extension UIViewController {
    public var disposer: Disposer {
        return view.disposer
    }
}
