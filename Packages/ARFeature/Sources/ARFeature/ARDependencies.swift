//  ARDependencies.swift
//  ARFeature — 체험 화면이 읽는 Core 계약(수집 종 + 도감 마스터). 실구현 연결은 S9.

import Foundation
import CorePackage

public struct ARDependencies: Sendable {
    public var collection: any CollectionRepository
    public var species: any SpeciesRepository

    public init(collection: any CollectionRepository, species: any SpeciesRepository) {
        self.collection = collection
        self.species = species
    }

    /// Mock: 카멜레온을 수집한 상태로 시드(체험 가능 종 1개).
    public static var mock: ARDependencies {
        let epoch = Date(timeIntervalSince1970: 0)
        return ARDependencies(
            collection: MockCollectionRepository(entries: [
                CollectionEntry(speciesId: "chameleon", captureCount: 1, discovered: true,
                                firstSeenAt: epoch, lastSeenAt: epoch, isFavorite: false)
            ]),
            species: MockSpeciesRepository()
        )
    }
}
