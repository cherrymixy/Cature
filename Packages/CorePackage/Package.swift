// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CorePackage",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "CorePackage", targets: ["CorePackage"]),
    ],
    targets: [
        .target(name: "CorePackage"),
    ]
)
