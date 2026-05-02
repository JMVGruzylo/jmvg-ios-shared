// swift-tools-version: 5.9
// JMVGAuth — shared auth utilities for ro-control-ios + ro-tools-ios.

import PackageDescription

let package = Package(
    name: "jmvg-ios-shared",
    platforms: [
        .iOS(.v16),
        .macOS(.v13), // for `swift test` on the CLI; not used by app builds
    ],
    products: [
        .library(
            name: "JMVGAuth",
            targets: ["JMVGAuth"]
        ),
    ],
    targets: [
        .target(
            name: "JMVGAuth",
            path: "Sources/JMVGAuth"
        ),
        .testTarget(
            name: "JMVGAuthTests",
            dependencies: ["JMVGAuth"],
            path: "Tests/JMVGAuthTests"
        ),
    ]
)
