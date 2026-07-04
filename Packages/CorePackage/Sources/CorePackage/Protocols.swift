//  Protocols.swift
//  CorePackage — Cature 계약(프로토콜). Repository·Service 경계.
//
//  Feature는 Data/Services 구현이 아니라 이 프로토콜에 의존한다(주입으로 mock↔실구현 교체).
//  ⚠️ 계약. 변경은 승아만, 이벤트로(docs/contracts.md).

import Foundation

// MARK: - Repositories

/// 도감 마스터(큐레이션 세트) 읽기.
public protocol SpeciesRepository: Sendable {
    func allSpecies() async throws -> [Species]
    func species(id: String) async throws -> Species?
}

/// 발견 기록 저장·조회.
public protocol SightingRepository: Sendable {
    func allSightings() async throws -> [Sighting]
    func sightings(speciesId: String) async throws -> [Sighting]
    /// 발견 1건 저장. (사진 로컬 복사·좌표·시각은 구현체 책임.)
    func save(_ sighting: Sighting) async throws
}

/// 종별 수집 상태.
public protocol CollectionRepository: Sendable {
    func allEntries() async throws -> [CollectionEntry]
    func entry(speciesId: String) async throws -> CollectionEntry?
    /// 저장 규칙(PRD §3.4): captureCount += 1, discovered = true, lastSeenAt = date.
    /// 첫 발견이면 firstSeenAt = date. 갱신된 엔트리를 반환.
    @discardableResult
    func recordCapture(speciesId: String, at date: Date) async throws -> CollectionEntry
    func setFavorite(speciesId: String, _ isFavorite: Bool) async throws
}

/// 사용자 프로필 저장·조회.
public protocol ProfileRepository: Sendable {
    func load() async throws -> UserProfile?
    func save(_ profile: UserProfile) async throws
}

// MARK: - Services

/// LLM 두뇌: 종 식별 + 공존 카드 생성.
public protocol LLMService: Sendable {
    /// 이미지 → 후보 배열(confidence 내림차순). 저확신/비생물은 낮은 confidence로.
    func identify(image: Data) async throws -> [AnalysisCandidate]
    /// 확정 종 → 공존 카드. (캐시는 구현체 책임: 큐레이션 우선 → LLM 생성 후 캐시.)
    func coexistCard(speciesId: String) async throws -> CoexistCard
}

/// 위치 표본(좌표 + 역지오코딩 이름).
public struct LocationSample: Codable, Hashable, Sendable {
    public let latitude: Double
    public let longitude: Double
    public let locationName: String?

    public init(latitude: Double, longitude: Double, locationName: String? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
    }
}

/// 현재 위치. 권한 거부/불가 시 nil(좌표 없이 진행).
public protocol LocationService: Sendable {
    func currentLocation() async -> LocationSample?
}

/// 촬영/선택 → 임시 파일 URL.
public protocol CaptureService: Sendable {
    func capturePhoto() async throws -> URL
}
