// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LiveKitComponents",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
    ],
    products: [
        .library(
            name: "LiveKitComponents",
            targets: ["LiveKitComponents"]
        ),
    ],
    dependencies: [
        .package(name: "LiveKit", url: "https://github.com/livekit/client-sdk-swift.git", .exact("1.0.13")),
        .package(url: "https://github.com/apple/swift-docc-plugin.git", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "LiveKitComponents",
            dependencies: ["LiveKit"],
            path: "Sources"
        ),
        .testTarget(
            name: "LiveKitComponentsTests",
            dependencies: ["LiveKitComponents"]
        ),
    ]
)
