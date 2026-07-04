//  OpenAIClient.swift
//  ServicesPackage — OpenAI 설정 + 주입 가능한 HTTP 전송(테스트에서 stub으로 교체).

import Foundation

public enum ServiceError: Error, Sendable, Equatable {
    case invalidResponse
    case http(status: Int, body: String?)
    case emptyContent
    case decoding(String)
}

public struct OpenAIConfig: Sendable {
    public var apiKey: String
    public var model: String
    public var baseURL: URL

    // TODO(프로덕션): 키를 클라이언트에 두지 말고 프록시 경유. 데모는 로컬 config(비커밋).
    public init(
        apiKey: String,
        model: String = "gpt-4o",
        baseURL: URL = URL(string: "https://api.openai.com/v1")!
    ) {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
    }
}

/// POST 요청을 보내고 본문 Data를 돌려주는 최소 전송 계층. 테스트는 stub 주입.
public protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> Data
}

public struct URLSessionTransport: HTTPTransport {
    let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func send(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ServiceError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw ServiceError.http(status: http.statusCode, body: String(data: data, encoding: .utf8))
        }
        return data
    }
}
