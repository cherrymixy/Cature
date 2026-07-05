// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DiscoveryFeature",
    platforms: [.iOS(.v17), .macOS(.v14)],   // macOS = 호스트 빌드/프리뷰용(실타깃 iOS 17)
    products: [
        .library(name: "DiscoveryFeature", targets: ["DiscoveryFeature"]),
    ],
    dependencies: [
        .package(path: "../CorePackage"),
        .package(path: "../DesignTokens"),
    ],
    targets: [
        .target(
            name: "DiscoveryFeature",
            dependencies: [
                .product(name: "CorePackage", package: "CorePackage"),
                .product(name: "DesignTokens", package: "DesignTokens"),
            ],
            resources: [
                .process("Resources/CreatureAssets.xcassets"),
            ]
        ),
        .testTarget(
            name: "DiscoveryFeatureTests",
            dependencies: [
                "DiscoveryFeature",
                .product(name: "CorePackage", package: "CorePackage"),
            ]
        ),
    ]
)
