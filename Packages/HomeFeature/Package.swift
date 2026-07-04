// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HomeFeature",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "HomeFeature", targets: ["HomeFeature"]),
    ],
    dependencies: [
        .package(path: "../CorePackage"),
        .package(path: "../DesignTokens"),
    ],
    targets: [
        .target(
            name: "HomeFeature",
            dependencies: [
                .product(name: "CorePackage", package: "CorePackage"),
                .product(name: "DesignTokens", package: "DesignTokens"),
            ],
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
