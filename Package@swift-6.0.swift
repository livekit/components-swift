// swift-tools-version:6.0
// (Xcode16.0+)

import PackageDescription

let package = Package(
    name: "LiveKitComponents",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .macCatalyst(.v14),
        .visionOS(.v1),
        .tvOS(.v17),
    ],
    products: [
        .library(
            name: "LiveKitComponents",
            targets: ["LiveKitComponents"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/livekit/client-sdk-swift.git", from: "2.6.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin.git", from: "1.4.3"),
    ],
    targets: [
        .target(
            name: "LiveKitComponents",
            dependencies: [
                .product(name: "LiveKit", package: "client-sdk-swift"),
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "LiveKitComponentsTests",
            dependencies: ["LiveKitComponents"]
        ),
    ],
    swiftLanguageModes: [
        .v5, // opt-out from dynamic actor isolation checks
        .v6,
    ]
)
