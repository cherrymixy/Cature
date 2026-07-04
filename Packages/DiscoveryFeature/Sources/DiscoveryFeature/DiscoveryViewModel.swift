//  DiscoveryViewModel.swift
//  DiscoveryFeature — 발견 플로우 상태기계(촬영→분석→공존카드→수집연출).

import Foundation
import Observation
import CorePackage

enum DiscoveryStep {
    case camera
    case analyzing
    case candidates([AnalysisCandidate])
    case notFound
    case coexist(CoexistCard, species: Species?, candidate: AnalysisCandidate)
    case collected(name: String, captureCount: Int, achievement: Double, canExperience: Bool)
}

@MainActor
@Observable
final class DiscoveryViewModel {
    private(set) var step: DiscoveryStep = .camera

    private let deps: DiscoveryDependencies
    private var lastPhoto: URL?
    private var lastLocation: LocationSample?
    private var lastCandidates: [AnalysisCandidate] = []

    init(deps: DiscoveryDependencies) {
        self.deps = deps
    }

    /// 촬영 → 위치 → 식별(후보).
    func capture() async {
        do {
            let photo = try await deps.capture.capturePhoto()
            lastPhoto = photo
            step = .analyzing
            lastLocation = await deps.location.currentLocation()
            let image = (try? Data(contentsOf: photo)) ?? Data()
            let candidates = try await deps.llm.identify(image: image)
            lastCandidates = candidates
            step = candidates.isEmpty ? .notFound : .candidates(candidates)
        } catch {
            step = .camera   // 취소/실패 → 카메라로
        }
    }

    func retake() {
        step = .camera
    }

    /// 후보 1개 확정(자동 확정 아님) → 공존 카드.
    func select(_ candidate: AnalysisCandidate) async {
        guard let speciesId = candidate.speciesId else {
            step = .notFound   // 도감(큐레이션) 대상 아님
            return
        }
        step = .analyzing
        let species = try? await deps.species.species(id: speciesId)
        let card = (try? await deps.llm.coexistCard(speciesId: speciesId)) ?? Self.fallbackCard(speciesId)
        step = .coexist(card, species: species, candidate: candidate)
    }

    /// 저장(PRD §3.4): Sighting 생성 + captureCount+1 + discovered → 수집 연출.
    func save() async {
        guard case let .coexist(_, species, candidate) = step, let speciesId = candidate.speciesId else { return }
        let now = Date()
        let sighting = Sighting(
            id: UUID().uuidString,
            speciesId: speciesId,
            photoPath: lastPhoto?.lastPathComponent ?? "",
            latitude: lastLocation?.latitude,
            longitude: lastLocation?.longitude,
            locationName: lastLocation?.locationName,
            candidates: lastCandidates,
            createdAt: now
        )
        try? await deps.sightings.save(sighting)
        let entry = try? await deps.collection.recordCapture(speciesId: speciesId, at: now)
        let discovered = (try? await deps.collection.allEntries().filter { $0.discovered }.count) ?? 0
        let total = (try? await deps.species.allSpecies().count) ?? 0
        step = .collected(
            name: species?.nameKo ?? candidate.displayName,
            captureCount: entry?.captureCount ?? 1,
            achievement: CollectionMath.achievement(discoveredCount: discovered, totalSpecies: total),
            canExperience: species?.canExperience ?? false
        )
    }

    func reset() {
        step = .camera
    }

    private static func fallbackCard(_ speciesId: String) -> CoexistCard {
        CoexistCard(
            speciesId: speciesId,
            intro: "이 생명에 대해 조금 더 알아가 볼까요?",
            needs: ["안전한 서식 공간", "먹이와 물"],
            disturbances: ["갑작스러운 접근", "서식지 훼손"],
            source: .llm
        )
    }
}
