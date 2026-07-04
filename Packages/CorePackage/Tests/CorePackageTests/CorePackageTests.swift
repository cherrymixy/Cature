//  CorePackageTests.swift
//  계약 경계 테스트: 모델 Codable + Mock 동작 + 수집 규칙.

import Testing
import Foundation
@testable import CorePackage

@Suite("CorePackage 계약")
struct CorePackageTests {

    @Test("모델 Codable 라운드트립")
    func codableRoundTrip() throws {
        let sighting = Sighting(
            id: "s1", speciesId: "chameleon", photoPath: "/tmp/p.jpg",
            latitude: 37.5, longitude: 127.0, locationName: "서울",
            candidates: SampleData.identifyCandidates,
            createdAt: Date(timeIntervalSince1970: 0)
        )
        let data = try JSONEncoder().encode(sighting)
        let decoded = try JSONDecoder().decode(Sighting.self, from: data)
        #expect(decoded == sighting)
    }

    @Test("MockLLMService.identify — 고정 후보, 내림차순")
    func identifyFixedCandidates() async throws {
        let candidates = try await MockLLMService().identify(image: Data())
        #expect(candidates.count == 3)
        #expect(candidates.first?.displayName == "카멜레온")
        #expect(candidates.map(\.confidence) == [0.78, 0.24, 0.02])
        #expect(candidates == candidates.sorted { $0.confidence > $1.confidence })
    }

    @Test("공존 카드 — 카멜레온은 큐레이션, 나머지는 폴백")
    func coexistCards() async throws {
        let service = MockLLMService()
        let chameleon = try await service.coexistCard(speciesId: "chameleon")
        #expect(chameleon.source == .curated)
        #expect(chameleon.needs.contains { $0.contains("나뭇가지") })
        #expect(chameleon.disturbances.contains { $0.contains("만지기") })

        let other = try await service.coexistCard(speciesId: "lizard")
        #expect(other.source == .llm)
    }

    @Test("저장 규칙 — captureCount+1 · discovered · firstSeenAt 유지")
    func recordCaptureRule() async throws {
        let repo = MockCollectionRepository()
        let day0 = Date(timeIntervalSince1970: 0)
        let first = try await repo.recordCapture(speciesId: "chameleon", at: day0)
        #expect(first.captureCount == 1)
        #expect(first.discovered)

        let day1 = Date(timeIntervalSince1970: 86_400)
        let second = try await repo.recordCapture(speciesId: "chameleon", at: day1)
        #expect(second.captureCount == 2)
        #expect(second.firstSeenAt == day0)   // 첫 발견 시각 유지
        #expect(second.lastSeenAt == day1)
    }

    @Test("달성률 = 발견 종수 / 전체 종수 (상한 1)")
    func achievementFormula() {
        #expect(CollectionMath.achievement(discoveredCount: 3, totalSpecies: 6) == 0.5)
        #expect(CollectionMath.achievement(discoveredCount: 0, totalSpecies: 0) == 0)
        #expect(CollectionMath.achievement(discoveredCount: 9, totalSpecies: 6) == 1)
    }

    @Test("씨앗 종 — 3개 이상 + usdz 없는 종은 체험 비활성")
    func seedSpecies() async throws {
        let repo = MockSpeciesRepository()
        let all = try await repo.allSpecies()
        #expect(all.count >= 3)
        let ladybug = try await repo.species(id: "ladybug")
        #expect(ladybug?.canExperience == false)
        let chameleon = try await repo.species(id: "chameleon")
        #expect(chameleon?.canExperience == true)
    }

    @Test("발견기록 저장·조회")
    func sightingSaveLoad() async throws {
        let repo = MockSightingRepository()
        let s = Sighting(id: "s1", speciesId: "lizard", photoPath: "/tmp/a.jpg", createdAt: Date(timeIntervalSince1970: 0))
        try await repo.save(s)
        #expect(try await repo.allSightings().count == 1)
        #expect(try await repo.sightings(speciesId: "lizard").first == s)
        #expect(try await repo.sightings(speciesId: "chameleon").isEmpty)
    }
}
