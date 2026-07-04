// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ServicesPackage",
    platforms: [.iOS(.v17), .macOS(.v14)],   // macOS = 호스트 swift test용(실타깃 iOS 17)
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
            ],
            resources: [
                .process("Resources"),   // 외부화된 LLM 프롬프트(identify/coexist)
            ]
        ),
        .testTarget(
            name: "ServicesPackageTests",
            dependencies: [
                "ServicesPackage",
                .product(name: "CorePackage", package: "CorePackage"),
            ]
        ),
    ]
)
