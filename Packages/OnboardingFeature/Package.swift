// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OnboardingFeature",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "OnboardingFeature", targets: ["OnboardingFeature"]),
    ],
    dependencies: [
        .package(path: "../CorePackage"),
        .package(path: "../DesignTokens"),
    ],
    targets: [
        .target(
            name: "OnboardingFeature",
            dependencies: [
                .product(name: "CorePackage", package: "CorePackage"),
                .product(name: "DesignTokens", package: "DesignTokens"),
            ]
        ),
    ]
)
