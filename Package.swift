// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WarmasterStudio",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "WarmasterStudio",
            path: "Sources/WarmasterStudio",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "WarmasterStudioTests",
            dependencies: ["WarmasterStudio"],
            path: "Tests/WarmasterStudioTests"
        )
    ]
)
