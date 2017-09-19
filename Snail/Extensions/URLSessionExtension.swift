//  Copyright © 2017 Compass. All rights reserved.

import UIKit

extension URLSession {
    public enum ErrorType: Error {
        case invalidData
        case invalidResponse
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
        return observer
    }

    public func data(request: URLRequest) -> Observable<(Data, URLResponse)> {
        let observer = Replay<(Data, URLResponse)>(1)
        let task = dataTask(with: request, completionHandler: { data, response, error in
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
        })
        task.resume()
        return observer
    }

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
        return observer
    }
}
