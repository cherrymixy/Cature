// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DesignTokens",
    platforms: [.iOS(.v17), .macOS(.v14)],   // macOS = 호스트 swift build/preview용(실타깃은 iOS 17)
    products: [
        .library(name: "DesignTokens", targets: ["DesignTokens"]),
    ],
    targets: [
        // 순수 디자인 레이어 — 도메인(Core)에 의존하지 않는다(의존 0).
        .target(
            name: "DesignTokens",
            resources: [
                .process("Resources"),   // 번들 폰트(Josefin Sans) — 코드로 런타임 등록
            ]
        ),
    ]
)
