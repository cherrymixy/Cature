//  MinigameFeature.swift
//  Cature — 미니게임: 카드 뒤집기→가위바위보 (찬희).

import CorePackage
import Foundation
import SwiftUI

public struct RootView: View {
    @StateObject private var viewModel: MinigameIntegrationViewModel

    public init(
        collectionRepository: any CollectionRepository = MockCollectionRepository(),
        speciesRepository: any SpeciesRepository = MockSpeciesRepository()
    ) {
        _viewModel = StateObject(
            wrappedValue: MinigameIntegrationViewModel(
                collectionRepository: collectionRepository,
                speciesRepository: speciesRepository
            )
        )
    }

    public var body: some View {
        MinigameIntegrationView(viewModel: viewModel)
            .task {
                await viewModel.load()
            }
    }
}

struct MinigameIntegrationView: View {
    @ObservedObject var viewModel: MinigameIntegrationViewModel

    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("기능")
                            .font(.title.bold())
                        Text(viewModel.summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("게임") {
                    GamePolicyRow(
                        title: "Catch Your Card",
                        subtitle: viewModel.cardFlipPolicy,
                        isReady: viewModel.canStartCardFlip
                    )

                    GamePolicyRow(
                        title: "가위바위보",
                        subtitle: viewModel.rockPaperScissorsPolicy,
                        isReady: viewModel.canStartRockPaperScissors
                    )
                }

                if viewModel.playableRows.isEmpty {
                    Section {
                        MinigameEmptyPolicyView(
                            title: "수집한 생물이 없어요",
                            message: "실데이터 주입 전에는 Mock 종으로 미니게임 프리뷰를 확인합니다."
                        )
                    }
                } else {
                    Section("게임 후보") {
                        ForEach(viewModel.playableRows) { row in
                            HStack {
                                Text(row.symbol)
                                    .font(.headline)
                                    .frame(width: 32, height: 32)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(row.name)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Text(row.detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("미니게임")
        }
    }
}

struct MinigameEmptyPolicyView: View {
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

struct GamePolicyRow: View {
    let title: String
    let subtitle: String
    let isReady: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isReady ? "checkmark.circle.fill" : "exclamationmark.circle")
                .foregroundStyle(isReady ? .green : .secondary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .accessibilityLabel("\(title), \(subtitle)")
    }
}

@MainActor
final class MinigameIntegrationViewModel: ObservableObject {
    @Published private(set) var summary = "Mock 데이터 확인 중"
    @Published private(set) var playableRows: [MinigameSpeciesRow] = []
    @Published private(set) var canStartCardFlip = false
    @Published private(set) var canStartRockPaperScissors = false
    @Published private(set) var cardFlipPolicy = "6종 이상이면 12장 매칭 게임 가능"
    @Published private(set) var rockPaperScissorsPolicy = "1종 이상이면 상대 생물 선택 가능"

    private let collectionRepository: any CollectionRepository
    private let speciesRepository: any SpeciesRepository

    init(
        collectionRepository: any CollectionRepository,
        speciesRepository: any SpeciesRepository
    ) {
        self.collectionRepository = collectionRepository
        self.speciesRepository = speciesRepository
    }

    func load() async {
        do {
            let species = try await speciesRepository.allSpecies()
            let entries = try await collectionRepository.allEntries()
            apply(species: species, entries: entries)
        } catch {
            apply(species: [], entries: [])
        }
    }

    private func apply(species: [Species], entries: [CollectionEntry]) {
        let entriesBySpecies = Dictionary(uniqueKeysWithValues: entries.map { ($0.speciesId, $0) })
        let discoveredSpecies = species.filter { entriesBySpecies[$0.id]?.discovered == true }
        let playableSpecies = discoveredSpecies.isEmpty ? species : discoveredSpecies

        playableRows = playableSpecies.map { MinigameSpeciesRow(species: $0, entry: entriesBySpecies[$0.id]) }
        canStartCardFlip = playableSpecies.count >= 2
        canStartRockPaperScissors = !playableSpecies.isEmpty

        summary = "\(playableSpecies.count)종 사용 가능"
        cardFlipPolicy = playableSpecies.count >= 6
            ? "6쌍 12장 구성이 가능해요."
            : "\(playableSpecies.count)종으로 축소 덱 또는 Mock fallback 필요"
        rockPaperScissorsPolicy = playableSpecies.isEmpty
            ? "상대 생물이 없어 시작할 수 없어요."
            : "\(playableSpecies[0].nameKo) 등으로 상대 선택 가능"
    }
}

struct MinigameSpeciesRow: Identifiable, Equatable {
    let id: String
    let name: String
    let symbol: String
    let detail: String

    init(species: Species, entry: CollectionEntry?) {
        id = species.id
        name = species.nameKo
        symbol = String(species.nameKo.prefix(1))

        let source = entry?.discovered == true ? "수집 종" : "Mock 후보"
        let media = species.thumbnail == nil ? "썸네일 없음" : "썸네일 있음"
        detail = "\(source) · \(media)"
    }
}

#if !CLI_BUILD
#Preview {
    RootView(
        collectionRepository: MockCollectionRepository(),
        speciesRepository: MockSpeciesRepository()
    )
}
#endif
