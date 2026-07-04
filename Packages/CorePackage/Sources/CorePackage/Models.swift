//  Models.swift
//  CorePackage — Cature 데이터 모델 (PRD §2, Codable). 계약 SSOT.
//
//  ⚠️ 이 파일은 계약이다. 변경은 승아만, 그리고 이벤트(docs/contracts.md 공표 + 승인).

import Foundation

/// 공존 카드 출처.
public enum CardSource: String, Codable, Hashable, Sendable {
    case curated   // 검수된 큐레이션 캐시
    case llm       // LLM 생성
}

/// 사용자 프로필.
public struct UserProfile: Codable, Hashable, Identifiable, Sendable {
    public let userId: String
    public var nickname: String
    public var profileImagePath: String?

    public var id: String { userId }

    public init(userId: String, nickname: String, profileImagePath: String? = nil) {
        self.userId = userId
        self.nickname = nickname
        self.profileImagePath = profileImagePath
    }
}

/// 도감 마스터 종 (data/로 외부화되는 큐레이션 세트).
public struct Species: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let nameKo: String
    public let category: String        // 파충류, 양서류, 곤충 …
    public let usdzAsset: String?      // 없으면 AR 체험 비활성
    public let thumbnail: String?

    public init(id: String, nameKo: String, category: String, usdzAsset: String? = nil, thumbnail: String? = nil) {
        self.id = id
        self.nameKo = nameKo
        self.category = category
        self.usdzAsset = usdzAsset
        self.thumbnail = thumbnail
    }

    /// usdz 보유 → AR 체험 가능.
    public var canExperience: Bool { usdzAsset != nil }
}

/// 종별 공존 카드 (캐시 대상).
public struct CoexistCard: Codable, Hashable, Sendable {
    public let speciesId: String
    public let intro: String
    public let needs: [String]          // 이 생명에게 필요한 조건
    public let disturbances: [String]   // 사람이 방해할 수 있는 행동
    public let source: CardSource

    public init(speciesId: String, intro: String, needs: [String], disturbances: [String], source: CardSource) {
        self.speciesId = speciesId
        self.intro = intro
        self.needs = needs
        self.disturbances = disturbances
        self.source = source
    }
}

/// 식별 후보 1개 (정보 정확도 포함).
public struct AnalysisCandidate: Codable, Hashable, Sendable {
    public let speciesId: String?      // 큐레이션 종이 아니면 nil
    public let displayName: String
    public let confidence: Double      // 0.0 ~ 1.0 (진짜 확률 아님 → "정보 정확도")
    public let category: String?       // 동물 · 식물 · 곤충 … (분석 화면 라벨)

    public init(speciesId: String?, displayName: String, confidence: Double, category: String? = nil) {
        self.speciesId = speciesId
        self.displayName = displayName
        self.confidence = confidence
        self.category = category
    }
}

/// 저장된 발견 1건.
public struct Sighting: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let speciesId: String
    public let photoPath: String
    public let latitude: Double?
    public let longitude: Double?
    public let locationName: String?
    public let candidates: [AnalysisCandidate]
    public let createdAt: Date

    public init(
        id: String,
        speciesId: String,
        photoPath: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        locationName: String? = nil,
        candidates: [AnalysisCandidate] = [],
        createdAt: Date
    ) {
        self.id = id
        self.speciesId = speciesId
        self.photoPath = photoPath
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
        self.candidates = candidates
        self.createdAt = createdAt
    }
}

/// 종별 수집 상태.
public struct CollectionEntry: Codable, Hashable, Identifiable, Sendable {
    public let speciesId: String
    public var captureCount: Int
    public var discovered: Bool
    public var firstSeenAt: Date
    public var lastSeenAt: Date
    public var isFavorite: Bool

    public var id: String { speciesId }

    public init(
        speciesId: String,
        captureCount: Int,
        discovered: Bool,
        firstSeenAt: Date,
        lastSeenAt: Date,
        isFavorite: Bool
    ) {
        self.speciesId = speciesId
        self.captureCount = captureCount
        self.discovered = discovered
        self.firstSeenAt = firstSeenAt
        self.lastSeenAt = lastSeenAt
        self.isFavorite = isFavorite
    }
}
