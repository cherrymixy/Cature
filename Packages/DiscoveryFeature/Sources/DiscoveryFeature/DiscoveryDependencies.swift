//  DiscoveryDependencies.swift
//  DiscoveryFeature — 발견 플로우가 주입받는 Core 계약 묶음.
//  구현이 아니라 프로토콜에 의존 → mock↔실구현 교체. 실구현 연결은 통합(S9).

import Foundation
import CorePackage

public struct DiscoveryDependencies: Sendable {
    public var capture: any CaptureService
    public var llm: any LLMService
    public var location: any LocationService
    public var species: any SpeciesRepository
    public var sightings: any SightingRepository
    public var collection: any CollectionRepository

    public init(
        capture: any CaptureService,
        llm: any LLMService,
        location: any LocationService,
        species: any SpeciesRepository,
        sightings: any SightingRepository,
        collection: any CollectionRepository
    ) {
        self.capture = capture
        self.llm = llm
        self.location = location
        self.species = species
        self.sightings = sightings
        self.collection = collection
    }

    /// Core Mock 기반(시뮬레이터·프리뷰). S9에서 실구현으로 교체.
    public static var mock: DiscoveryDependencies {
        DiscoveryDependencies(
            capture: MockCaptureService(),
            llm: MockLLMService(),
            location: MockLocationService(),
            species: MockSpeciesRepository(),
            sightings: MockSightingRepository(),
            collection: MockCollectionRepository()
        )
    }
}
