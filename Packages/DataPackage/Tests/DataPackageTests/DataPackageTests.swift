//  DataPackageTests.swift
//  경계 테스트: 저장→재실행(새 인스턴스) 유지 · 저장 규칙 · now 주입 · 달성률.

import Testing
import Foundation
@testable import DataPackage
import CorePackage

@Suite("DataPackage 로컬 저장")
struct DataPackageTests {

    /// 테스트별 격리 임시 디렉터리.
    private func tempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("cature-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test("Sighting — 저장 후 재실행(새 인스턴스)에서 유지")
    func sightingPersists() async throws {
        let url = try tempDir().appendingPathComponent("sightings.json")
        let s = Sighting(id: "s1", speciesId: "chameleon", photoPath: "p.jpg",
                         createdAt: Date(timeIntervalSince1970: 0))
        try await LocalSightingRepository(fileURL: url).save(s)

        let reopened = LocalSightingRepository(fileURL: url)   // "재실행"
        #expect(try await reopened.allSightings() == [s])
        #expect(try await reopened.sightings(speciesId: "lizard").isEmpty)
    }

    @Test("Collection — 저장 규칙 + 재실행 유지")
    func collectionRuleAndPersist() async throws {
        let url = try tempDir().appendingPathComponent("collection.json")
        let repo = LocalCollectionRepository(fileURL: url)
        let day0 = Date(timeIntervalSince1970: 0)
        try await repo.recordCapture(speciesId: "chameleon", at: day0)
        let e2 = try await repo.recordCapture(speciesId: "chameleon", at: Date(timeIntervalSince1970: 86_400))
        #expect(e2.captureCount == 2)
        #expect(e2.discovered)
        #expect(e2.firstSeenAt == day0)

        let reopened = LocalCollectionRepository(fileURL: url)
        #expect(try await reopened.entry(speciesId: "chameleon")?.captureCount == 2)
    }

    @Test("Profile — UserDefaults 저장/로드/재실행")
    func profilePersists() async throws {
        let suite = "cature.test.\(UUID().uuidString)"
        defer { UserDefaults().removePersistentDomain(forName: suite) }

        let repo = LocalProfileRepository(suiteName: suite)
        #expect(try await repo.load() == nil)
        let profile = UserProfile(userId: "u1", nickname: "승아")
        try await repo.save(profile)

        let reopened = LocalProfileRepository(suiteName: suite)
        #expect(try await reopened.load() == profile)
    }

    @Test("PhotoStore — 복사 후 존재, 삭제 후 제거")
    func photoStore() throws {
        let dir = try tempDir()
        let temp = dir.appendingPathComponent("incoming.jpg")
        try Data([0x1, 0x2, 0x3]).write(to: temp)

        let store = PhotoStore(directory: dir.appendingPathComponent("Photos"))
        let name = try store.store(tempURL: temp)
        #expect(FileManager.default.fileExists(atPath: store.url(for: name).path))
        try store.remove(name: name)
        #expect(!FileManager.default.fileExists(atPath: store.url(for: name).path))
    }

    @Test("DiscoveryStore — now/id 주입, 저장 규칙 한 번에")
    func discoverySaveFlow() async throws {
        let dir = try tempDir()
        let sightings = LocalSightingRepository(fileURL: dir.appendingPathComponent("s.json"))
        let collection = LocalCollectionRepository(fileURL: dir.appendingPathComponent("c.json"))
        let photos = PhotoStore(directory: dir.appendingPathComponent("Photos"))
        let temp = dir.appendingPathComponent("shot.jpg")
        try Data([0x9]).write(to: temp)

        let fixed = Date(timeIntervalSince1970: 1_700_000_000)
        let store = DiscoveryStore(sightings: sightings, collection: collection, photos: photos,
                                   now: { fixed }, makeID: { "fixed-id" })

        let result = try await store.saveDiscovery(
            speciesId: "chameleon", photoTempURL: temp,
            candidates: SampleData.identifyCandidates,
            location: LocationSample(latitude: 37.5, longitude: 127, locationName: "서울")
        )
        #expect(result.sighting.id == "fixed-id")
        #expect(result.sighting.createdAt == fixed)
        #expect(result.sighting.locationName == "서울")
        #expect(result.entry.captureCount == 1)
        #expect(result.entry.discovered)
        #expect(try await sightings.allSightings().count == 1)
    }

    @Test("achievementRate — 발견 종수 / 전체 종수")
    func achievement() async throws {
        let dir = try tempDir()
        let collection = LocalCollectionRepository(fileURL: dir.appendingPathComponent("c.json"))
        try await collection.recordCapture(speciesId: "chameleon", at: Date(timeIntervalSince1970: 0))
        try await collection.recordCapture(speciesId: "lizard", at: Date(timeIntervalSince1970: 0))

        let species = LocalSpeciesRepository(species: SampleData.species)  // 5종
        let rate = try await achievementRate(collection: collection, species: species)
        #expect(rate == 0.4)   // 발견 2 / 전체 5
    }
}
