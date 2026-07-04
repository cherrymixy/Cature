// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ServicesPackage",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ServicesPackage", targets: ["ServicesPackage"]),
    ],
    dependencies: [
        .package(path: "../CorePackage"),
    ],
    targets: [
        .target(
            name: "ServicesPackage",
            dependencies: [
                .product(name: "CorePackage", package: "CorePackage"),
            ]
        ),
    ]
)
