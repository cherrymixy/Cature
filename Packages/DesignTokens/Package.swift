// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DesignTokens",
    platforms: [.iOS(.v17), .macOS(.v14)],   // macOS = 호스트 swift build/preview용(실타깃은 iOS 17)
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
