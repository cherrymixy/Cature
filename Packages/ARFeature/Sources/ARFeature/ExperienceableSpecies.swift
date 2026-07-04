//  ExperienceableSpecies.swift
//  ARFeature — 체험 가능 종 규칙(순수 함수, 크로스플랫폼 → 호스트 테스트).

import CorePackage

/// 체험 가능 = 수집(discovered)했고 && usdz 보유(canExperience). (PRD §3.7)
public func experienceableSpecies(collected: [CollectionEntry], allSpecies: [Species]) -> [Species] {
    let discoveredIds = Set(collected.filter { $0.discovered }.map(\.speciesId))
    return allSpecies.filter { $0.canExperience && discoveredIds.contains($0.id) }
}
