// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DesignTokens",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "DesignTokens", targets: ["DesignTokens"]),
    ],
    dependencies: [
        .package(path: "../CorePackage"),
    ],
    targets: [
        .target(
            name: "DesignTokens",
            dependencies: [
                .product(name: "CorePackage", package: "CorePackage"),
            ]
        ),
    ]
)
