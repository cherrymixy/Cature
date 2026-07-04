//  OpenAILLMService.swift
//  ServicesPackage — Core LLMService의 OpenAI 실구현 (PRD §5).
//  identify: 멀티모달(chat.completions + image_url) → json_schema 엄격 파싱 + 가드레일.
//  coexistCard: 캐시(큐레이션) 우선 → 없으면 생성 → 캐시.

import Foundation
import CorePackage

public struct OpenAILLMService: LLMService {
    let config: OpenAIConfig
    let transport: any HTTPTransport
    let prompts: PromptSet
    let cache: CoexistCache?

    public init(
        config: OpenAIConfig,
        transport: any HTTPTransport = URLSessionTransport(),
        prompts: PromptSet = .bundled(),
        cache: CoexistCache? = nil
    ) {
        self.config = config
        self.transport = transport
        self.prompts = prompts
        self.cache = cache
    }

    /// documents/캐시 기반 프로덕션 구성.
    public static func live(apiKey: String, model: String = "gpt-4o", curated: [CoexistCard] = []) -> OpenAILLMService {
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("coexist-cache.json")
        return OpenAILLMService(
            config: OpenAIConfig(apiKey: apiKey, model: model),
            transport: URLSessionTransport(),
            prompts: .bundled(),
            cache: CoexistCache(fileURL: cacheURL, curated: curated)
        )
    }

    // MARK: LLMService

    public func identify(image: Data) async throws -> [AnalysisCandidate] {
        let dataURL = "data:image/jpeg;base64,\(image.base64EncodedString())"
        let body = OpenAIBody.identify(model: config.model, systemPrompt: prompts.identify, imageDataURL: dataURL)
        let content = try await sendForContent(body)
        let result = try Self.decode(IdentifyResult.self, from: content)
        // 가드레일: 사람/무생물/판독불가 → 빈 후보(호출측이 '생물 아님' 분기).
        guard result.isBiological else { return [] }
        return result.candidates
            .map { AnalysisCandidate(speciesId: $0.speciesId, displayName: $0.displayName, confidence: $0.confidence) }
            .sorted { $0.confidence > $1.confidence }
    }

    public func coexistCard(speciesId: String) async throws -> CoexistCard {
        if let cache, let cached = await cache.card(for: speciesId) {
            return cached   // 큐레이션/이전 생성 캐시 우선
        }
        let body = OpenAIBody.coexist(model: config.model, systemPrompt: prompts.coexist, speciesId: speciesId)
        let content = try await sendForContent(body)
        let result = try Self.decode(CoexistResult.self, from: content)
        let card = CoexistCard(
            speciesId: speciesId,
            intro: result.intro,
            needs: result.needs,
            disturbances: result.disturbances,
            source: .llm
        )
        await cache?.store(card)
        return card
    }

    // MARK: Networking

    private func sendForContent(_ body: [String: Any]) async throws -> String {
        var request = URLRequest(url: config.baseURL.appendingPathComponent("chat/completions"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data = try await transport.send(request)
        let response = try Self.decode(ChatResponse.self, from: data)
        guard let content = response.choices.first?.message.content, !content.isEmpty else {
            throw ServiceError.emptyContent
        }
        return content
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do { return try JSONDecoder().decode(T.self, from: data) }
        catch { throw ServiceError.decoding(String(describing: error)) }
    }

    private static func decode<T: Decodable>(_ type: T.Type, from string: String) throws -> T {
        guard let data = string.data(using: .utf8) else { throw ServiceError.decoding("utf8") }
        return try decode(type, from: data)
    }
}

// MARK: - Response DTOs

private struct ChatResponse: Decodable {
    let choices: [Choice]
    struct Choice: Decodable { let message: Message }
    struct Message: Decodable { let content: String }
}

struct IdentifyResult: Decodable {
    let isBiological: Bool
    let candidates: [Candidate]
    struct Candidate: Decodable {
        let displayName: String
        let speciesId: String?
        let confidence: Double
    }
}

struct CoexistResult: Decodable {
    let intro: String
    let needs: [String]
    let disturbances: [String]
}

// MARK: - Request bodies (json_schema 엄격 모드)

enum OpenAIBody {
    static func identify(model: String, systemPrompt: String, imageDataURL: String) -> [String: Any] {
        [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": [
                    ["type": "text", "text": "이 사진 속 생물을 식별해줘."],
                    ["type": "image_url", "image_url": ["url": imageDataURL]],
                ]],
            ],
            "response_format": [
                "type": "json_schema",
                "json_schema": ["name": "identification", "strict": true, "schema": identifySchema],
            ],
        ]
    }

    static func coexist(model: String, systemPrompt: String, speciesId: String) -> [String: Any] {
        [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": "종 식별자: \(speciesId). 이 종의 공존 카드를 만들어줘."],
            ],
            "response_format": [
                "type": "json_schema",
                "json_schema": ["name": "coexist_card", "strict": true, "schema": coexistSchema],
            ],
        ]
    }

    static var identifySchema: [String: Any] { [
        "type": "object",
        "additionalProperties": false,
        "required": ["isBiological", "candidates"],
        "properties": [
            "isBiological": ["type": "boolean"],
            "candidates": [
                "type": "array",
                "items": [
                    "type": "object",
                    "additionalProperties": false,
                    "required": ["displayName", "speciesId", "confidence"],
                    "properties": [
                        "displayName": ["type": "string"],
                        "speciesId": ["type": ["string", "null"]],
                        "confidence": ["type": "number"],
                    ],
                ],
            ],
        ],
    ] }

    static var coexistSchema: [String: Any] { [
        "type": "object",
        "additionalProperties": false,
        "required": ["intro", "needs", "disturbances"],
        "properties": [
            "intro": ["type": "string"],
            "needs": ["type": "array", "items": ["type": "string"]],
            "disturbances": ["type": "array", "items": ["type": "string"]],
        ],
    ] }
}
