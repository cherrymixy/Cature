// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DiscoveryFeature",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "DiscoveryFeature", targets: ["DiscoveryFeature"]),
    ],
    dependencies: [
        .package(path: "../CorePackage"),
    ],
    targets: [
        .target(
            name: "DiscoveryFeature",
            dependencies: [
                .product(name: "CorePackage", package: "CorePackage"),
            ]
        ),
    ]
)
