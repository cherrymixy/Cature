// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ARFeature",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ARFeature", targets: ["ARFeature"]),
    ],
    dependencies: [
        .package(path: "../CorePackage"),
    ],
    targets: [
        .target(
            name: "ARFeature",
            dependencies: [
                .product(name: "CorePackage", package: "CorePackage"),
            ]
        ),
    ]
)
