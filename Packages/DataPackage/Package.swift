// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DataPackage",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "DataPackage", targets: ["DataPackage"]),
    ],
    dependencies: [
        .package(path: "../CorePackage"),
    ],
    targets: [
        .target(
            name: "DataPackage",
            dependencies: [
                .product(name: "CorePackage", package: "CorePackage"),
            ]
        ),
    ]
)
