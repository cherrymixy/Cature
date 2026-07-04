// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ARFeature",
    platforms: [.iOS(.v17), .macOS(.v14)],   // macOS = 호스트 테스트용(AR UI는 #if os(iOS))
    products: [
        .library(name: "ARFeature", targets: ["ARFeature"]),
    ],
    dependencies: [
        .package(path: "../CorePackage"),
        .package(path: "../DesignTokens"),
    ],
    targets: [
        .target(
            name: "ARFeature",
            dependencies: [
                .product(name: "CorePackage", package: "CorePackage"),
                .product(name: "DesignTokens", package: "DesignTokens"),
            ]
        ),
        .testTarget(
            name: "ARFeatureTests",
            dependencies: [
                "ARFeature",
                .product(name: "CorePackage", package: "CorePackage"),
            ]
        ),
    ]
)
