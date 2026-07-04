// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MinigameFeature",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "MinigameFeature", targets: ["MinigameFeature"]),
    ],
    dependencies: [
        .package(path: "../CorePackage"),
    ],
    targets: [
        .target(
            name: "MinigameFeature",
            dependencies: [
                .product(name: "CorePackage", package: "CorePackage"),
            ],
            resources: [
                .process("Resources/GameAssets.xcassets"),
            ]
        ),
    ]
)
