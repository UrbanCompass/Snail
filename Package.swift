// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Snail",
    products: [
        .library(name: "Snail", targets: ["Snail"])
    ],
    targets: [
        .target(name: "Snail", path: "Snail"),
        .testTarget(name: "SnailTests", dependencies: ["Snail"], path: "SnailTests")
    ]
)
