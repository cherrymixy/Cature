//  CodableFile.swift
//  DataPackage — Codable ↔ JSON 파일 최소 헬퍼 (경로 A).

import Foundation

enum CodableFile {
    /// 파일이 없거나 깨졌으면 nil.
    static func load<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    /// 상위 디렉터리 보장 + 원자적 쓰기.
    static func save<T: Encodable>(_ value: T, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try JSONEncoder().encode(value)
        try data.write(to: url, options: .atomic)
    }

    /// documents 하위 파일 URL.
    static func documentsFile(_ name: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(name)
    }
}
