//  PhotoStore.swift
//  DataPackage — 촬영 임시 파일을 documents 하위로 복사하고 경로를 관리 (PRD §6).
//  교체·삭제 시 옛 파일 정리(remove).

import Foundation

public struct PhotoStore: Sendable {
    public let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    /// documents/Photos 기본 위치.
    public static func inDocuments() -> PhotoStore {
        PhotoStore(directory: CodableFile.documentsFile("Photos"))
    }

    /// 저장 이름(상대) → 실제 URL.
    public func url(for name: String) -> URL {
        directory.appendingPathComponent(name)
    }

    /// 임시 파일을 사진 디렉터리로 복사하고 저장 이름을 반환.
    public func store(tempURL: URL) throws -> String {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let ext = tempURL.pathExtension.isEmpty ? "jpg" : tempURL.pathExtension
        let name = "\(UUID().uuidString).\(ext)"
        try FileManager.default.copyItem(at: tempURL, to: directory.appendingPathComponent(name))
        return name
    }

    /// 저장된 사진 삭제(없으면 무시).
    public func remove(name: String) throws {
        let target = directory.appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: target.path) {
            try FileManager.default.removeItem(at: target)
        }
    }
}
