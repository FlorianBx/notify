// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "notify",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "notify",
            targets: ["Notify"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0")
    ],
    targets: [
        .executableTarget(
            name: "Notify",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "NotifyTests",
            dependencies: ["Notify"]
        )
    ]
)