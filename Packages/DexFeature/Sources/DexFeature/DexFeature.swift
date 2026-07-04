//  DexFeature.swift
//  Cature — 도감/마이 (찬희).

import CorePackage
import Foundation
import SwiftUI

public struct RootView: View {
    @StateObject private var viewModel: DexIntegrationViewModel

    public init(
        collectionRepository: any CollectionRepository = MockCollectionRepository(),
        speciesRepository: any SpeciesRepository = MockSpeciesRepository(),
        profileRepository: any ProfileRepository = MockProfileRepository()
    ) {
        _viewModel = StateObject(
            wrappedValue: DexIntegrationViewModel(
                collectionRepository: collectionRepository,
                speciesRepository: speciesRepository,
                profileRepository: profileRepository
            )
        )
    }

    public var body: some View {
        DexIntegrationView(viewModel: viewModel)
            .task {
                await viewModel.load()
            }
    }
}

struct DexIntegrationView: View {
    @ObservedObject var viewModel: DexIntegrationViewModel

    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.nickname)
                            .font(.headline)
                        Text(viewModel.userIdLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("달성률") {
                    VStack(alignment: .leading, spacing: 8) {
                        ProgressView(value: viewModel.achievement)
                        Text(viewModel.achievementLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("도감") {
                    if viewModel.speciesRows.isEmpty {
                        EmptyPolicyView(
                            title: "도감 대상이 없어요",
                            message: "승아의 SpeciesRepository 실구현 또는 Mock 데이터를 확인해 주세요."
                        )
                    } else {
                        ForEach(viewModel.speciesRows) { row in
                            HStack(spacing: 12) {
                                Text(row.discovered ? "✓" : "○")
                                    .font(.headline)
                                    .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(row.name)
                                        .font(.body)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.8)
                                    Text(row.detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                            .accessibilityLabel(row.accessibilityLabel)
                        }
                    }
                }
            }
            .navigationTitle("도감")
        }
    }
}

struct EmptyPolicyView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}

@MainActor
final class DexIntegrationViewModel: ObservableObject {
    @Published private(set) var nickname = "Cature"
    @Published private(set) var userIdLabel = "@guest"
    @Published private(set) var speciesRows: [DexSpeciesRow] = []
    @Published private(set) var achievement = 0.0
    @Published private(set) var achievementLabel = "0 / 0"

    private let collectionRepository: any CollectionRepository
    private let speciesRepository: any SpeciesRepository
    private let profileRepository: any ProfileRepository

    init(
        collectionRepository: any CollectionRepository,
        speciesRepository: any SpeciesRepository,
        profileRepository: any ProfileRepository
    ) {
        self.collectionRepository = collectionRepository
        self.speciesRepository = speciesRepository
        self.profileRepository = profileRepository
    }

    func load() async {
        do {
            let profile = try await profileRepository.load()
            let species = try await speciesRepository.allSpecies()
            let entries = try await collectionRepository.allEntries()
            apply(profile: profile, species: species, entries: entries)
        } catch {
            apply(profile: nil, species: [], entries: [])
        }
    }

    private func apply(profile: UserProfile?, species: [Species], entries: [CollectionEntry]) {
        nickname = profile?.nickname ?? "Cature"
        userIdLabel = "@\(profile?.userId ?? "guest")"

        let entriesBySpecies = Dictionary(uniqueKeysWithValues: entries.map { ($0.speciesId, $0) })
        let discoveredCount = species.filter { entriesBySpecies[$0.id]?.discovered == true }.count

        achievement = species.isEmpty ? 0 : Double(discoveredCount) / Double(species.count)
        achievementLabel = "\(discoveredCount) / \(species.count)"
        speciesRows = species.map { item in
            let entry = entriesBySpecies[item.id]
            return DexSpeciesRow(species: item, entry: entry)
        }
    }
}

struct DexSpeciesRow: Identifiable, Equatable {
    let id: String
    let name: String
    let detail: String
    let discovered: Bool

    init(species: Species, entry: CollectionEntry?) {
        id = species.id
        name = species.nameKo
        discovered = entry?.discovered == true

        let captureCount = entry?.captureCount ?? 0
        let experienceText = species.canExperience ? "AR 가능" : "AR 준비중"
        detail = "\(species.category) · \(captureCount)회 발견 · \(experienceText)"
    }

    var accessibilityLabel: String {
        discovered ? "\(name), 수집됨" : "\(name), 아직 미수집"
    }
}

#if !CLI_BUILD
#Preview {
    RootView(
        collectionRepository: MockCollectionRepository(),
        speciesRepository: MockSpeciesRepository(),
        profileRepository: MockProfileRepository()
    )
}
#endif
