//  Copyright © 2017 Compass. All rights reserved.

#if os(iOS) || os(tvOS)
import UIKit
#else
import Foundation
#endif

extension URLSession {
    public enum ErrorType: LocalizedError {
        case invalidData
        case invalidResponse

        public var errorDescription: String? {
            switch self {
            case .invalidData: return NSLocalizedString("Invalid Data", comment: "")
            case .invalidResponse: return NSLocalizedString("Invalid Response", comment: "")
            }
        }
    }

    private static var disposerKey = "com.compass.Snail.URLSession.Disposer"
    
    var disposer: Disposer {
        if let disposer = objc_getAssociatedObject(self, &URLSession.disposerKey) as? Disposer {
            return disposer
        }
        let disposer = Disposer()
        objc_setAssociatedObject(self, &URLSession.disposerKey, disposer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return disposer
    }

    public func decoded<T: Codable>(request: URLRequest) -> Observable<(T, URLResponse)> {
        let observer = Replay<(T, URLResponse)>(1)
        data(request: request).subscribe(onNext: { data, response in
            guard let codedObject = try? JSONDecoder().decode(T.self, from: data) else {
                observer.on(.error(ErrorType.invalidData))
                return
            }
            observer.on(.next((codedObject, response)))
        }, onError: { observer.on(.error($0)) })
        .add(to: disposer)
        return observer
    }

    public func dictionary(request: URLRequest) -> Observable<([String: Any], URLResponse)> {
        let observer = Replay<([String: Any], URLResponse)>(1)
        data(request: request).subscribe(onNext: { data, response in
            guard let object = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers), let dictionary = object as? [String: Any] else {
                observer.on(.error(ErrorType.invalidData))
                return
            }
            observer.on(.next((dictionary, response)))
        }, onError: { observer.on(.error($0)) })
        .add(to: disposer)
        return observer
    }

    public func array(request: URLRequest) -> Observable<([Any], URLResponse)> {
        let observer = Replay<([Any], URLResponse)>(1)
        data(request: request).subscribe(onNext: { data, response in
            guard let object = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers), let dictionary = object as? [Any] else {
                observer.on(.error(ErrorType.invalidData))
                return
            }
            observer.on(.next((dictionary, response)))
        }, onError: { observer.on(.error($0)) })
        .add(to: disposer)
        return observer
    }

    public func data(request: URLRequest) -> Observable<(Data, URLResponse)> {
        let observer = Replay<(Data, URLResponse)>(1)
        let task = dataTask(with: request) { data, response, error in
            if let error = error {
                observer.on(.error(error))
                return
            }
            guard let data = data else {
                observer.on(.error(ErrorType.invalidData))
                return
            }
            guard let response = response else {
                observer.on(.error(ErrorType.invalidResponse))
                return
            }
            observer.on(.next((data, response)))
        }
        task.resume()
        return observer
    }

    #if os(iOS) || os(tvOS)
    public func image(request: URLRequest) -> Observable<(UIImage, URLResponse)> {
        let observer = Replay<(UIImage, URLResponse)>(1)
        data(request: request).subscribe(queue: .main, onNext: { data, response in
            guard let image = UIImage(data: data) else {
                observer.on(.error(ErrorType.invalidData))
                return
            }
            observer.on(.next((image, response)))
            observer.on(.done)
        }, onError: { observer.on(.error($0)) })
        .add(to: disposer)
        return observer
    }
    #endif
}
