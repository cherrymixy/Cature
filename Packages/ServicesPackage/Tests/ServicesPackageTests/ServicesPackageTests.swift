//  ServicesPackageTests.swift
//  stub transport로 파싱·정렬·가드레일·캐시 검증(실네트워크 없음).

import Testing
import Foundation
@testable import ServicesPackage
import CorePackage

/// OpenAI chat.completions 응답 봉투(choices[0].message.content = JSON 문자열).
private func chatResponse(contentJSON: String) -> Data {
    let obj: [String: Any] = ["choices": [["message": ["content": contentJSON]]]]
    return try! JSONSerialization.data(withJSONObject: obj)
}

/// 호출 횟수를 세는 stub 전송.
private actor CountingTransport: HTTPTransport {
    let payload: Data
    private(set) var calls = 0
    init(payload: Data) { self.payload = payload }
    func send(_ request: URLRequest) async throws -> Data {
        calls += 1
        return payload
    }
}

private func service(_ transport: any HTTPTransport, cache: CoexistCache? = nil) -> OpenAILLMService {
    OpenAILLMService(
        config: OpenAIConfig(apiKey: "test"),
        transport: transport,
        prompts: PromptSet(identify: "sys", coexist: "sys"),
        cache: cache
    )
}

@Suite("ServicesPackage — OpenAI LLM")
struct ServicesPackageTests {

    @Test("identify — 후보 파싱 + confidence 내림차순")
    func identifyParsesAndSorts() async throws {
        let content = #"{"isBiological": true, "candidates": [{"displayName":"도마뱀","speciesId":"lizard","confidence":0.24},{"displayName":"카멜레온","speciesId":"chameleon","confidence":0.78},{"displayName":"버섯","speciesId":null,"confidence":0.02}]}"#
        let candidates = try await service(CountingTransport(payload: chatResponse(contentJSON: content)))
            .identify(image: Data([0x1]))
        #expect(candidates.count == 3)
        #expect(candidates.first?.displayName == "카멜레온")           // 정렬됨
        #expect(candidates.map(\.confidence) == [0.78, 0.24, 0.02])
        #expect(candidates.last?.speciesId == nil)                    // 비큐레이션
    }

    @Test("identify 가드레일 — isBiological=false → 빈 후보")
    func identifyGuardrail() async throws {
        let content = #"{"isBiological": false, "candidates": []}"#
        let candidates = try await service(CountingTransport(payload: chatResponse(contentJSON: content)))
            .identify(image: Data())
        #expect(candidates.isEmpty)
    }

    @Test("빈/깨진 응답 — 안전하게 throw")
    func decodingError() async {
        let bad = chatResponse(contentJSON: "이건 JSON이 아님")
        await #expect(throws: ServiceError.self) {
            _ = try await service(CountingTransport(payload: bad)).identify(image: Data())
        }
    }

    @Test("coexistCard — 생성 후 캐시(두 번째 호출은 네트워크 안 탐)")
    func coexistCaches() async throws {
        let content = #"{"intro":"소개","needs":["a","b"],"disturbances":["c"]}"#
        let transport = CountingTransport(payload: chatResponse(contentJSON: content))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("coexist-\(UUID().uuidString).json")
        let cache = CoexistCache(fileURL: url)
        let svc = service(transport, cache: cache)

        let first = try await svc.coexistCard(speciesId: "lizard")
        #expect(first.source == .llm)
        #expect(first.needs == ["a", "b"])
        _ = try await svc.coexistCard(speciesId: "lizard")   // 캐시 히트
        #expect(await transport.calls == 1)
    }

    @Test("coexistCard — 큐레이션 캐시 우선(API 안 탐)")
    func curatedWins() async throws {
        let transport = CountingTransport(payload: chatResponse(contentJSON: "{}"))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("coexist-\(UUID().uuidString).json")
        let cache = CoexistCache(fileURL: url, curated: [SampleData.chameleonCard])
        let card = try await service(transport, cache: cache).coexistCard(speciesId: "chameleon")
        #expect(card.source == .curated)
        #expect(await transport.calls == 0)
    }
}
