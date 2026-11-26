// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "GoogleAIUsageWidget",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "GoogleAIUsageWidget",
            targets: ["GoogleAIUsageWidget"]
        )
    ],
    targets: [
        .executableTarget(
            name: "GoogleAIUsageWidget",
            path: "Sources/GoogleAIUsageWidget"
        ),
        .testTarget(
            name: "GoogleAIUsageWidgetTests",
            dependencies: ["GoogleAIUsageWidget"],
            path: "Tests/GoogleAIUsageWidgetTests"
        )
    ]
)
