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
        .package(url: "https://github.com/pipecat-ai/pipecat-client-ios.git", from: "0.3.0"),
        .package(url: "https://github.com/pipecat-ai/pipecat-client-ios-daily.git", from: "0.3.0"),
    ],
    targets: [
        .target(
            name: "RevveAI",
            dependencies: [
                .product(name: "PipecatClientIOS", package: "pipecat-client-ios"),
                .product(name: "PipecatClientIOSDaily", package: "pipecat-client-ios-daily")
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
