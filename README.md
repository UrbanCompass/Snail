# 🐌 snail [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) ![Cocoapods](https://cocoapod-badges.herokuapp.com/v/Snail/badge.png) ![codecov.io](https://codecov.io/gh/UrbanCompass/snail/branch/master/graphs/badge.svg) ![SwiftPM Compatible](https://img.shields.io/badge/SwiftPM-Compatible-brightgreen.svg)

[![SNAIL](https://img.youtube.com/vi/u4QAnCFd4iw/0.jpg)](https://www.youtube.com/watch?v=u4QAnCFd4iw)

A lightweight observables framework, also available in [Kotlin](https://github.com/UrbanCompass/Snail-Kotlin)

## Installation

### Carthage

You can install [Carthage](https://github.com/Carthage/Carthage) with [Homebrew](http://brew.sh/) using the following command:

```bash
brew update
brew install carthage
```
To integrate Snail into your Xcode project using Carthage, specify it in your `Cartfile` where `"x.x.x"` is the current release:

```ogdl
github "UrbanCompass/Snail" "x.x.x"
```

### Swift Package Manager

To install using [Swift Package Manager](https://swift.org/package-manager/) have your Swift package set up, and add Snail as a dependency to your `Package.swift`.

```swift
dependencies: [
    .Package(url: "https://github.com/UrbanCompass/Snail.git", majorVersion: 0)
]
```

### Manually
Add all the files from `Snail/Snail` to your project

### Developing Locally

1. Run the setup script to install required dependencies `./scripts/setup.sh`

## Creating Observables

```swift
let observable = Observable<thing>()
```

## Disposer
### What the Disposer IS

The disposer is used to maintain reference to many subscriptions in a single location. When a disposer is deinitialized, it removes all of its referenced subscriptions from memory. A disposer is usually located in a centralized place where most of the subscriptions happen (ie: UIViewController in an MVVM architecture). Since most of the subscriptions are to different observables, and those observables are tied to type, all the things that are going to be disposed need to comform to `Disposable`. 

### What the Disposer IS NOT

The disposer is not meant to prevent retain cycles. A common example is a `UIViewController` that has reference to a `Disposer` object. A subscription definition might look something like this:

```swift
extension MyViewController {
  button.tap.subscribe(onNext: { [weak self] in
    self?.navigationController.push(newVc)
  }).add(to: disposer)
}
```
Without specifying a `[weak self]` capture list in a scenario like this, a retain cycle is created between the subscriber and the view controller. In this example, without the capture list, the view controller will not be deallocated as expected, causing its disposer object to stay in memory as well. Since the `Disposer` removes its referenced subscribers when it is deinitialized, these subscribers will stay in memory as well.

See [https://docs.swift.org/swift-book/LanguageGuide/AutomaticReferenceCounting.html](https://docs.swift.org/swift-book/LanguageGuide/AutomaticReferenceCounting.html) for more details on memory management in Swift.

## Closure Wrapper

The main usage for the `Disposer` is to get rid of subscription closures that we create on `Observables`, but the other usage that we found handy, is the ability to dispose of regular closures. As part of the library, we created a small `Closure` wrapper class that complies with `Disposable`. This way you can wrap simple closures to be disposed. 


```swift
let closureCall = Closure {
    print("We ❤️ Snail")
}.add(to: Disposer)
```

Please note that this would not dispose of the `closureCall` reference to closure, it would only Dispose the content of the `Closure`.

## Subscribing to Observables

```swift
observable.subscribe(
    onNext: { thing in ... }, // do something with thing
    onError: { error in ... }, // do something with error
    onDone: { ... } //do something when it's done
).add(to: disposer)
```

Closures are optional too...

```swift
observable.subscribe(
    onNext: { thing in ... } // do something with thing
).add(to: disposer)
```

```swift
observable.subscribe(
    onError: { error in ... } // do something with error
).add(to: disposer)
```

## Creating Observables Variables

```swift
let variable = Variable<whatever>(some initial value)
```

```swift
let optionalString = Variable<String?>(nil)
optionalString.asObservable().subscribe(
    onNext: { string in ... } // do something with value changes
).add(to: disposer)

optionalString.value = "something"
```

```swift
let int = Variable<Int>(12)
int.asObservable().subscribe(
    onNext: { int in ... } // do something with value changes
).add(to: disposer)

int.value = 42
```

## Combining Observable Variables


```swift
let isLoaderAnimating = Variable<Bool>(false)
isLoaderAnimating.bind(to: viewModel.isLoading) // forward changes from one Variable to another

viewModel.isLoading = true
print(isLoaderAnimating.value) // true
```

```swift
Observable.merge([userCreated, userUpdated]).subscribe(
  onNext: { user in ... } // do something with the latest value that got updated
}).add(to: disposer)

userCreated.value = User(name: "Russell") // triggers 
userUpdated.value = User(name: "Lee") // triggers 
```

```swift
Observable.combineLatest((isMapLoading, isListLoading)).subscribe(
  onNext: { isMapLoading, isListLoading in ... } // do something when both values are set, every time one gets updated
}).add(to: disposer)

isMapLoading.value = true
isListLoading.value = true // triggers
```

## Miscellaneous Observables

```swift
let just = Just(1) // always returns the initial value (1 in this case)

enum TestError: Error {
  case test
}
let failure = Fail(TestError.test) // always fail with error

let n = 5
let replay = Replay(n) // replays the last N events when a new observer subscribes
```

## Operators

Snail provides some basic operators in order to transform and operate on observables. 

- `map`: This operator allows to map the value of an obsverable into another value. Similar to `map` on `Collection` types.

  ```swift
  let observable = Observable<Int>()
  let subject = observable.map { "Number: \($0)" }
  // -> subject emits `String` whenever `observable` emits.
  ```
- `filter`: This operator allows filtering out certain values from the observable chain. Similar to `filter` on `Collection` types. You simply return `true` if the value should be emitted and `false` to filter it out.

  ```swift
  let observable = Observable<Int>()
  let subject = observable.filter { $0 % 2 == 0 }
  // -> subject will only emit even numbers.
  ```
- `flatMap`: This operator allows mapping values into other observables, for example you may want to create an observable for a network request when a user tap observable emits.

  ```swift
  let fetchTrigger = Observable<Void>()
  let subject = fetchTrigger.flatMap { Variable(100).asObservable() }
  // -> subject is an `Observable<Int>` that is created when `fetchTrigger` emits.
  ```

## Subscribing to Control Events

```swift
let control = UIControl()
control.controlEvent(.touchUpInside).subscribe(
  onNext: { ... }  // do something with thing
).add(to: disposer)

let button = UIButton()
button.tap.subscribe(
  onNext: { ... }  // do something with thing
).add(to: disposer)
```

## Queues

You can specify which queue an observables will be notified on by using `.subscribe(queue: <desired queue>)`. If you don't specify, then the observable will be notified on the same queue that the observable published on.

There are 3 scenarios:

1. You don't specify the queue. Your observer will be notified on the same thread as the observable published on.

2. You specified `main` queue AND the observable published on the `main` queue. Your observer will be notified synchronously on the `main` queue.

3. You specified a queue. Your observer will be notified async on the specified queue.

### Examples

Subscribing on `DispatchQueue.main`

```swift
observable.subscribe(queue: .main,
    onNext: { thing in ... }
).add(to: disposer)
```

# In Practice

## Subscribing to Notifications

```swift
NotificationCenter.default.observeEvent(Notification.Name.UIKeyboardWillShow)
  .subscribe(queue: .main, onNext: { notification in
    self.keyboardWillShow(notification)
  }).add(to: disposer)
```

## Subscribing to Gestures

```swift
let panGestureRecognizer = UIPanGestureRecognizer()
panGestureRecognizer.asObservable()
  .subscribe(queue: .main, onNext: { sender in
    // Your code here
  }).add(to: disposer)
view.addGestureRecognizer(panGestureRecognizer)
```

## Subscribing to UIBarButton Taps

```swift
navigationItem.leftBarButtonItem?.tap
  .subscribe(onNext: {
    self.dismiss(animated: true, completion: nil)
  }).add(to: disposer)
```
