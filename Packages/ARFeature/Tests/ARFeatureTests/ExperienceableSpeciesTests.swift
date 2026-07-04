//  ExperienceableSpeciesTests.swift
//  체험 가능 종 규칙(수집 && usdz). UI/AR 없이 로직만.

import Testing
import Foundation
import CorePackage
@testable import ARFeature

@Suite("체험 가능 종")
struct ExperienceableSpeciesTests {

    private func entry(_ id: String, discovered: Bool = true) -> CollectionEntry {
        let epoch = Date(timeIntervalSince1970: 0)
        return CollectionEntry(speciesId: id, captureCount: 1, discovered: discovered,
                               firstSeenAt: epoch, lastSeenAt: epoch, isFavorite: false)
    }

    @Test("수집 && usdz 보유만 체험 가능")
    func onlyCollectedWithUsdz() {
        // chameleon: usdz O, ladybug: usdz X
        let result = experienceableSpecies(
            collected: [entry("chameleon"), entry("ladybug")],
            allSpecies: SampleData.species
        )
        #expect(result.map(\.id) == ["chameleon"])
    }

    @Test("미수집 종은 제외")
    func excludesNotCollected() {
        #expect(experienceableSpecies(collected: [], allSpecies: SampleData.species).isEmpty)
    }

    @Test("discovered=false는 제외")
    func excludesNotDiscovered() {
        let result = experienceableSpecies(
            collected: [entry("chameleon", discovered: false)],
            allSpecies: SampleData.species
        )
        #expect(result.isEmpty)
    }
}
