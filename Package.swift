// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProductivityTracker",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "ProductivityTracker",
            targets: ["ProductivityTracker"]
        )
    ],
    dependencies: [
        // KeyboardShortcuts library for global shortcuts
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0")
    ],
    targets: [
        .executableTarget(
            name: "ProductivityTracker",
            dependencies: [
                "KeyboardShortcuts"
            ],
            path: "ProductivityTracker"
        )
    ]
)
