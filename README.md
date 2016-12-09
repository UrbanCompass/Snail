# 🐌

[![SNAIL](https://img.youtube.com/vi/u4QAnCFd4iw/0.jpg)](https://www.youtube.com/watch?v=u4QAnCFd4iw)

## Creating Observables

```swift
let observable = Observable<thing>()
```

## Subscribing to Observables

### Using closures
```swift
observable.subscribe(
    onNext: { thing in ... }, // do something with thing
    onError: { error in ... }, // do something with error
    onDone: { ... } //do something when it's done
)
```

Closures are optional too...

```swift
observable.subscribe(
    onNext: { thing in ... }, // do something with thing
)
```

### Using raw event
```swift
observable.subscribe { event in
    switch event {
    case .next(let thing):
        // do something with thing
    case .error(let error):
        // do something with error
    case .done:
        // do something when it's done
    }
}
```
