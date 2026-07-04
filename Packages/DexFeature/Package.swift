// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DexFeature",
    platforms: [.iOS(.v17), .macOS(.v10_15)],
    products: [
        .library(name: "DexFeature", targets: ["DexFeature"]),
    ],
    dependencies: [
        .package(path: "../CorePackage"),
    ],
    targets: [
        .target(
            name: "DexFeature",
            dependencies: [
                .product(name: "CorePackage", package: "CorePackage"),
            ]
        ),
    ]
)
