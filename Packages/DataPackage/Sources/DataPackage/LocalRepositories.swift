//  LocalRepositories.swift
//  DataPackage — CorePackage 리포지토리 프로토콜의 로컬 구현 (경로 A).
//  상태=UserDefaults, 기록=Codable JSON 파일. actor로 가변 상태를 안전하게.
//  ⚠️ Core의 Mock은 유지(교체는 통합 때, S9).

import Foundation
import CorePackage

// MARK: - Profile (UserDefaults)

public actor LocalProfileRepository: ProfileRepository {
    private let defaults: UserDefaults
    private let key: String

    /// `suiteName`을 주면 그 도메인 사용(테스트 격리용), 없으면 `.standard`.
    public init(suiteName: String? = nil, key: String = "cature.profile") {
        self.defaults = suiteName.flatMap { UserDefaults(suiteName: $0) } ?? .standard
        self.key = key
    }

    public func load() -> UserProfile? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(UserProfile.self, from: data)
    }

    public func save(_ profile: UserProfile) throws {
        defaults.set(try JSONEncoder().encode(profile), forKey: key)
    }
}

// MARK: - Sighting (JSON 파일)

public actor LocalSightingRepository: SightingRepository {
    private let url: URL
    private var cache: [Sighting]

    public init(fileURL: URL? = nil) {
        let url = fileURL ?? CodableFile.documentsFile("sightings.json")
        self.url = url
        self.cache = CodableFile.load([Sighting].self, from: url) ?? []
    }

    public func allSightings() -> [Sighting] { cache }
    public func sightings(speciesId: String) -> [Sighting] { cache.filter { $0.speciesId == speciesId } }

    public func save(_ sighting: Sighting) throws {
        cache.append(sighting)
        try CodableFile.save(cache, to: url)
    }
}

// MARK: - Collection (JSON 파일 + 저장 규칙)

public actor LocalCollectionRepository: CollectionRepository {
    private let url: URL
    private var entries: [String: CollectionEntry]

    public init(fileURL: URL? = nil) {
        let url = fileURL ?? CodableFile.documentsFile("collection.json")
        self.url = url
        let loaded = CodableFile.load([CollectionEntry].self, from: url) ?? []
        self.entries = Dictionary(uniqueKeysWithValues: loaded.map { ($0.speciesId, $0) })
    }

    public func allEntries() -> [CollectionEntry] { Array(entries.values) }
    public func entry(speciesId: String) -> CollectionEntry? { entries[speciesId] }

    /// PRD §3.4: captureCount += 1, discovered = true, lastSeenAt = date, 첫 발견이면 firstSeenAt = date.
    @discardableResult
    public func recordCapture(speciesId: String, at date: Date) throws -> CollectionEntry {
        let updated: CollectionEntry
        if var existing = entries[speciesId] {
            existing.captureCount += 1
            existing.discovered = true
            existing.lastSeenAt = date
            updated = existing
        } else {
            updated = CollectionEntry(
                speciesId: speciesId, captureCount: 1, discovered: true,
                firstSeenAt: date, lastSeenAt: date, isFavorite: false
            )
        }
        entries[speciesId] = updated
        try persist()
        return updated
    }

    public func setFavorite(speciesId: String, _ isFavorite: Bool) throws {
        guard var entry = entries[speciesId] else { return }
        entry.isFavorite = isFavorite
        entries[speciesId] = entry
        try persist()
    }

    private func persist() throws {
        try CodableFile.save(Array(entries.values), to: url)
    }
}

// MARK: - Species (읽기 전용 마스터)

public actor LocalSpeciesRepository: SpeciesRepository {
    private let master: [Species]

    /// 명시 종 목록.
    public init(species: [Species]) {
        self.master = species
    }

    /// JSON 파일이 있으면 로드, 없으면 seed로 폴백(도감 마스터는 data/로 외부화 예정).
    public init(fileURL: URL, seed: [Species]) {
        self.master = CodableFile.load([Species].self, from: fileURL) ?? seed
    }

    public func allSpecies() -> [Species] { master }
    public func species(id: String) -> Species? { master.first { $0.id == id } }
}
