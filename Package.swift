// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "RevveAI",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "RevveAI",
            targets: ["RevveAI"]
        ),
    ],
    
    dependencies: [
        .package(url: "https://github.com/livekit/client-sdk-swift.git", from: "2.5.0"), // Core SDK
    ],
    targets: [
        .target(
            name: "RevveAI",
            dependencies: [
                .product(name: "LiveKit", package: "client-sdk-swift"),
            ],
            path: "Sources/RevveAI"
        ),
        .testTarget(
            name: "RevveAITests",
            dependencies: ["RevveAI"],
            path: "Tests/RevveAITests"
        ),
    ]
)
