// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MirrorKit",
    platforms: [.macOS(.v14)],
    products: [
        // Captures and displays the iPhone screen over USB.
        .library(name: "Video", targets: ["Video"]),
        // Sends touches and keys to the iPhone (v0.2+).
        .library(name: "Control", targets: ["Control"]),
    ],
    targets: [
        .target(name: "Video"),
        .target(name: "Control"),
        .testTarget(name: "VideoTests", dependencies: ["Video"]),
    ]
)
