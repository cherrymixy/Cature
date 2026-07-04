// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DexFeature",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "DexFeature", targets: ["DexFeature"]),
    ],
    dependencies: [
        .package(path: "../CorePackage"),
        .package(path: "../DesignTokens"),
    ],
    targets: [
        .target(
            name: "DexFeature",
            dependencies: [
                .product(name: "CorePackage", package: "CorePackage"),
                .product(name: "DesignTokens", package: "DesignTokens"),
            ],
            resources: [
                .process("Media.xcassets"),
            ]
        ),
    ]
)
