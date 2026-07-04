//  MockRepositories.swift
//  CorePackage/Mocks — 메모리 배열로 동작하는 Repository 목 (actor = Sendable + 안전한 가변 상태).

import Foundation

/// 씨앗 종을 읽는 도감 목.
public actor MockSpeciesRepository: SpeciesRepository {
    private let seed: [Species]

    public init(species: [Species] = SampleData.species) {
        self.seed = species
    }

    public func allSpecies() async throws -> [Species] { seed }
    public func species(id: String) async throws -> Species? { seed.first { $0.id == id } }
}

/// 메모리 프로필 목.
public actor MockProfileRepository: ProfileRepository {
    private var profile: UserProfile?

    public init(profile: UserProfile? = nil) {
        self.profile = profile
    }

    public func load() async throws -> UserProfile? { profile }
    public func save(_ profile: UserProfile) async throws { self.profile = profile }
}

/// 메모리 발견기록 목.
public actor MockSightingRepository: SightingRepository {
    private var storage: [Sighting]

    public init(sightings: [Sighting] = []) {
        self.storage = sightings
    }

    public func allSightings() async throws -> [Sighting] { storage }
    public func sightings(speciesId: String) async throws -> [Sighting] {
        storage.filter { $0.speciesId == speciesId }
    }
    public func save(_ sighting: Sighting) async throws { storage.append(sighting) }
}

/// 메모리 수집상태 목. 저장 규칙(PRD §3.4)을 그대로 구현.
public actor MockCollectionRepository: CollectionRepository {
    private var entries: [String: CollectionEntry]

    public init(entries: [CollectionEntry] = []) {
        self.entries = Dictionary(uniqueKeysWithValues: entries.map { ($0.speciesId, $0) })
    }

    public func allEntries() async throws -> [CollectionEntry] { Array(entries.values) }
    public func entry(speciesId: String) async throws -> CollectionEntry? { entries[speciesId] }

    @discardableResult
    public func recordCapture(speciesId: String, at date: Date) async throws -> CollectionEntry {
        if var existing = entries[speciesId] {
            existing.captureCount += 1
            existing.discovered = true
            existing.lastSeenAt = date
            entries[speciesId] = existing
            return existing
        }
        let fresh = CollectionEntry(
            speciesId: speciesId,
            captureCount: 1,
            discovered: true,
            firstSeenAt: date,
            lastSeenAt: date,
            isFavorite: false
        )
        entries[speciesId] = fresh
        return fresh
    }

    public func setFavorite(speciesId: String, _ isFavorite: Bool) async throws {
        guard var entry = entries[speciesId] else { return }
        entry.isFavorite = isFavorite
        entries[speciesId] = entry
    }
}
