# 🐌 snail ![CircleCI](https://www.bitrise.io/app/61dfbf95cb424467.svg?token=S_HeFeReob26U7Geod5VLg&branch=master) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) ![Cocoapods](https://cocoapod-badges.herokuapp.com/v/Snail/badge.png) ![codecov.io](https://codecov.io/gh/UrbanCompass/snail/branch/master/graphs/badge.svg) ![SwiftPM Compatible](https://img.shields.io/badge/SwiftPM-Compatible-brightgreen.svg)

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

## Creating Observables

```swift
let observable = Observable<thing>()
```

## Subscribing to Observables

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
    onNext: { thing in ... } // do something with thing
)
```

```swift
observable.subscribe(
    onError: { error in ... } // do something with error
)
```

## Creating Observables Variables

```swift
let variable = Variable<whatever>(some initial value)
```

```swift
let optionalString = Variable<String?>(nil)
optionalString.asObservable().subscribe(
    onNext: { string in ... } // do something with value changes
)

optionalString.value = "something"
```

```swift
let int = Variable<Int>(12)
int.asObservable().subscribe(
    onNext: { int in ... } // do something with value changes
)

int.value = 42
```

## Miscellaneous Observables

```swift
let just = Just(1) // always returns the initial value (1 in this case)

enum TestError: Error {
  case test
}
let failure = Fail(TestError.test) //always fail with error

let n = 5
let replay = Replay(n) // replays the last N events when a new observer subscribes
```

## Subscribing to Control Events

```swift
let control = UIControl()
control.controlEvent(.touchUpInside).subscribe(
  onNext: { ... }  // do something with thing
)

let button = UIButton()
button.tap.subscribe(
  onNext: { ... }  // do something with thing
)
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
)
```

## Weak self

To avoid retain cycles and/or crashes, __always__ use `[weak self]` when self is needed by an observer

```swift
observable.subscribe(onNext: { [weak self] in
    // use self? as needed.
})
```

# In Practice

## Subscribing to Notifications

```swift
NotificationCenter.default.observeEvent(Notification.Name.UIKeyboardWillShow)
  .subscribe(queue: .main, onNext: { [weak self] notification in
    self?.keyboardWillShow(notification)
  })
```

## Subscribing to Gestures

```swift
let panGestureRecognizer = UIPanGestureRecognizer()
panGestureRecognizer.asObservable()
  .subscribe(queue: .main, onNext: { [weak self] in
    self?.handlePan(panGestureRecognizer)
  })
view.addGestureRecognizer(panGestureRecognizer)
```

## Subscribing to UIBarButton Taps

```swift
navigationItem.leftBarButtonItem?.tap
  .subscribe(onNext: { [weak self] in
    self?.dismiss(animated: true, completion: nil)
  })
```
