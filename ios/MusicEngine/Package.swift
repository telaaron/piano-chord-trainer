// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MusicEngine",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "MusicEngine", targets: ["MusicEngine"]),
    ],
    targets: [
        .target(
            name: "MusicEngine",
            path: "Sources/MusicEngine"
        ),
        .testTarget(
            name: "MusicEngineTests",
            dependencies: ["MusicEngine"],
            path: "Tests/MusicEngineTests"
        ),
    ]
)
