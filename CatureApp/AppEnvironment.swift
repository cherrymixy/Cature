//  AppEnvironment.swift
//  Cature — 합성 루트(composition root). Feature에 실 구현(Data·Services)을 주입한다.
//  API 키: Config/Secrets.xcconfig → Info.plist(OpenAIAPIKey) → 여기서 읽음. 비면 Mock 폴백.
//  발견·AR·도감이 같은 로컬 저장을 공유하도록 repository는 단일 인스턴스로.

import Foundation
import CorePackage
import DataPackage
import ServicesPackage
import DiscoveryFeature
import ARFeature

@MainActor
enum AppEnvironment {

    // MARK: 공유 로컬 저장 (경로 A)
    static let species: any SpeciesRepository = LocalSpeciesRepository(species: SampleData.species)
    static let sightings: any SightingRepository = LocalSightingRepository()
    static let collection: any CollectionRepository = LocalCollectionRepository()
    static let profile: any ProfileRepository = LocalProfileRepository()

    // MARK: OpenAI 키
    /// 앱 번들의 Secrets.plist(비커밋, CatureApp/Secrets.plist) → OpenAIAPIKey. 없으면 빈 문자열.
    static var openAIKey: String {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let dict = NSDictionary(contentsOf: url) as? [String: Any],
              let key = dict["OpenAIAPIKey"] as? String
        else { return "" }
        return key.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 키가 있으면 실 OpenAI, 없으면 Mock (키 없이도 앱이 돎).
    static var llm: any LLMService {
        openAIKey.isEmpty
            ? MockLLMService()
            : OpenAILLMService.live(apiKey: openAIKey, curated: [SampleData.chameleonCard])
    }

    // MARK: Feature 의존성
    static var discovery: DiscoveryDependencies {
        DiscoveryDependencies(
            capture: ImagePickerCaptureService(),
            llm: llm,
            location: CoreLocationService(),
            species: species,
            sightings: sightings,
            collection: collection
        )
    }

    static var ar: ARDependencies {
        ARDependencies(collection: collection, species: species)
    }
}
