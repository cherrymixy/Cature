//  PromptSet.swift
//  ServicesPackage — 외부화된 프롬프트(패키지 리소스). 주입으로 교체 가능.

import Foundation

public struct PromptSet: Sendable {
    public let identify: String
    public let coexist: String

    public init(identify: String, coexist: String) {
        self.identify = identify
        self.coexist = coexist
    }

    /// Resources/{identify,coexist}.txt 에서 로드.
    public static func bundled() -> PromptSet {
        PromptSet(identify: load("identify"), coexist: load("coexist"))
    }

    private static func load(_ name: String) -> String {
        guard let url = Bundle.module.url(forResource: name, withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return ""
        }
        return text
    }
}
