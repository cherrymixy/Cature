//  DiscoveryStore.swift
//  DataPackage — "발견 저장" 복합 연산(PRD §3.4)과 달성률 계산.
//  now()·id 주입 가능 → 경계 단위테스트.

import Foundation
import CorePackage

public actor DiscoveryStore {
    private let sightings: any SightingRepository
    private let collection: any CollectionRepository
    private let photos: PhotoStore
    private let now: @Sendable () -> Date
    private let makeID: @Sendable () -> String

    public init(
        sightings: any SightingRepository,
        collection: any CollectionRepository,
        photos: PhotoStore,
        now: @escaping @Sendable () -> Date = { Date() },
        makeID: @escaping @Sendable () -> String = { UUID().uuidString }
    ) {
        self.sightings = sightings
        self.collection = collection
        self.photos = photos
        self.now = now
        self.makeID = makeID
    }

    /// 발견 저장: 사진 복사 → Sighting 생성(now) → 저장 → captureCount+1·discovered.
    @discardableResult
    public func saveDiscovery(
        speciesId: String,
        photoTempURL: URL,
        candidates: [AnalysisCandidate] = [],
        location: LocationSample? = nil
    ) async throws -> (sighting: Sighting, entry: CollectionEntry) {
        let timestamp = now()
        let storedName = try photos.store(tempURL: photoTempURL)
        let sighting = Sighting(
            id: makeID(),
            speciesId: speciesId,
            photoPath: storedName,
            latitude: location?.latitude,
            longitude: location?.longitude,
            locationName: location?.locationName,
            candidates: candidates,
            createdAt: timestamp
        )
        try await sightings.save(sighting)
        let entry = try await collection.recordCapture(speciesId: speciesId, at: timestamp)
        return (sighting, entry)
    }
}

/// 달성률 = 발견(discovered) 종수 ÷ 도감 대상 종수 (PRD §3.5).
public func achievementRate(
    collection: any CollectionRepository,
    species: any SpeciesRepository
) async throws -> Double {
    let discovered = try await collection.allEntries().filter { $0.discovered }.count
    let total = try await species.allSpecies().count
    return CollectionMath.achievement(discoveredCount: discovered, totalSpecies: total)
}
