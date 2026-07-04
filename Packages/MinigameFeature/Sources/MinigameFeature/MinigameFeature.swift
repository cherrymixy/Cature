//  MinigameFeature.swift
//  Cature — 미니게임: 카드 뒤집기→가위바위보 (찬희).

import CorePackage
import Foundation
import SwiftUI

public struct RootView: View {
    @StateObject private var viewModel: CatchYourCardViewModel

    public init(
        collectionRepository: any CollectionRepository = MockCollectionRepository(),
        speciesRepository: any SpeciesRepository = MockSpeciesRepository()
    ) {
        _viewModel = StateObject(
            wrappedValue: CatchYourCardViewModel(
                collectionRepository: collectionRepository,
                speciesRepository: speciesRepository
            )
        )
    }

    public var body: some View {
        CatchYourCardView(viewModel: viewModel)
            .task {
                await viewModel.load()
            }
    }
}

struct CatchYourCardView: View {
    @ObservedObject var viewModel: CatchYourCardViewModel

    private let gridColumns = Array(
        repeating: GridItem(.flexible(), spacing: 10),
        count: 3
    )

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    gameBoard
                    retryButton
                }
                .padding(18)
            }

            if viewModel.phase.showsOverlay {
                resultOverlay
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.cards)
        .animation(.easeInOut(duration: 0.2), value: viewModel.phase)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Catch Your Card")
                .font(.title.bold())

            HStack {
                Label("\(viewModel.remainingSeconds)s", systemImage: "timer")
                Spacer()
                Text("\(viewModel.matchedPairCount)/6")
            }
            .font(.headline)

            ProgressView(value: viewModel.progress)
        }
    }

    private var gameBoard: some View {
        LazyVGrid(columns: gridColumns, spacing: 10) {
            ForEach(viewModel.cards) { card in
                CatchCardView(card: card) {
                    viewModel.choose(card)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var retryButton: some View {
        Button {
            viewModel.restart()
        } label: {
            Label("다시 도전하기", systemImage: "arrow.clockwise")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    private var resultOverlay: some View {
        VStack(spacing: 14) {
            Image(systemName: viewModel.phase == .won ? "party.popper.fill" : "hourglass")
                .font(.largeTitle)

            Text(viewModel.phase.title)
                .font(.title.bold())

            Text(viewModel.phase.message)
                .font(.body)
                .multilineTextAlignment(.center)

            Button {
                viewModel.restart()
            } label: {
                Label("다시 도전하기", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: 320)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(radius: 18)
        .padding()
    }
}

struct CatchCardView: View {
    let card: CatchCard
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(card.isFaceUp || card.isMatched ? .regularMaterial : .thinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(.secondary, lineWidth: 1)
                    }

                VStack(spacing: 8) {
                    Text(card.isFaceUp || card.isMatched ? card.creature.symbol : "?")
                        .font(.largeTitle.bold())

                    Text(card.isFaceUp || card.isMatched ? card.creature.name : "Cature")
                        .font(.caption.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(8)
            }
            .aspectRatio(0.78, contentMode: .fit)
            .opacity(card.isMatched ? 0.68 : 1)
            .rotation3DEffect(
                .degrees(card.isFaceUp || card.isMatched ? 0 : 180),
                axis: (x: 0, y: 1, z: 0)
            )
        }
        .buttonStyle(.plain)
        .disabled(card.isMatched)
        .accessibilityLabel(card.accessibilityLabel)
    }
}

@MainActor
final class CatchYourCardViewModel: ObservableObject {
    @Published private(set) var cards: [CatchCard] = []
    @Published private(set) var remainingSeconds = 30
    @Published private(set) var phase: CatchGamePhase = .loading

    private let collectionRepository: any CollectionRepository
    private let speciesRepository: any SpeciesRepository
    private var timerTask: Task<Void, Never>?
    private var openedCardIDs: [CatchCard.ID] = []
    private var isResolvingMismatch = false
    private var creatures: [CatchCreature] = []

    init(
        collectionRepository: any CollectionRepository,
        speciesRepository: any SpeciesRepository
    ) {
        self.collectionRepository = collectionRepository
        self.speciesRepository = speciesRepository
    }

    var matchedPairCount: Int {
        cards.filter(\.isMatched).count / 2
    }

    var progress: Double {
        Double(remainingSeconds) / Double(Self.gameDuration)
    }

    func load() async {
        guard cards.isEmpty else { return }

        do {
            let loadedSpecies = try await playableSpecies()
            creatures = Self.creatures(from: loadedSpecies)
            restart()
        } catch {
            creatures = Self.fallbackCreatures
            restart()
        }
    }

    func restart() {
        timerTask?.cancel()
        remainingSeconds = Self.gameDuration
        phase = .playing
        openedCardIDs = []
        isResolvingMismatch = false
        cards = Self.makeDeck(from: creatures)
        startTimer()
    }

    func choose(_ card: CatchCard) {
        guard phase == .playing,
              !isResolvingMismatch,
              !card.isMatched,
              !card.isFaceUp,
              openedCardIDs.count < 2,
              let index = cards.firstIndex(where: { $0.id == card.id })
        else { return }

        cards[index].isFaceUp = true
        openedCardIDs.append(card.id)

        guard openedCardIDs.count == 2 else { return }
        resolveOpenedCards()
    }

    private func playableSpecies() async throws -> [Species] {
        let allSpecies = try await speciesRepository.allSpecies()
        let entries = try await collectionRepository.allEntries()
        let discoveredIDs = Set(entries.filter(\.discovered).map(\.speciesId))

        if discoveredIDs.isEmpty {
            return Array(allSpecies.prefix(Self.pairCount))
        }

        let discoveredSpecies = allSpecies.filter { discoveredIDs.contains($0.id) }
        let remainingSpecies = allSpecies.filter { !discoveredIDs.contains($0.id) }
        return Array((discoveredSpecies + remainingSpecies).prefix(Self.pairCount))
    }

    private func resolveOpenedCards() {
        let selected = cards.filter { openedCardIDs.contains($0.id) }
        guard selected.count == 2 else { return }

        if selected[0].creature.id == selected[1].creature.id {
            for cardID in openedCardIDs {
                if let index = cards.firstIndex(where: { $0.id == cardID }) {
                    cards[index].isMatched = true
                }
            }
            openedCardIDs = []
            checkWin()
        } else {
            isResolvingMismatch = true
            let mismatchIDs = openedCardIDs
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 750_000_000)
                self?.hideMismatch(mismatchIDs)
            }
        }
    }

    private func hideMismatch(_ mismatchIDs: [CatchCard.ID]) {
        for cardID in mismatchIDs {
            if let index = cards.firstIndex(where: { $0.id == cardID }) {
                cards[index].isFaceUp = false
            }
        }
        openedCardIDs = []
        isResolvingMismatch = false
    }

    private func checkWin() {
        guard cards.allSatisfy(\.isMatched) else { return }
        timerTask?.cancel()
        phase = .won
    }

    private func startTimer() {
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                self?.tick()
            }
        }
    }

    private func tick() {
        guard phase == .playing else { return }

        if remainingSeconds > 1 {
            remainingSeconds -= 1
        } else {
            remainingSeconds = 0
            timerTask?.cancel()
            phase = cards.allSatisfy(\.isMatched) ? .won : .lost
        }
    }

    private static func creatures(from species: [Species]) -> [CatchCreature] {
        var result = species.map {
            CatchCreature(
                id: $0.id,
                name: $0.nameKo,
                symbol: String($0.nameKo.prefix(1))
            )
        }

        for fallback in fallbackCreatures where result.count < pairCount {
            if !result.contains(where: { $0.id == fallback.id }) {
                result.append(fallback)
            }
        }

        return Array(result.prefix(pairCount))
    }

    private static func makeDeck(from creatures: [CatchCreature]) -> [CatchCard] {
        creatures
            .flatMap { creature in
                [
                    CatchCard(creature: creature),
                    CatchCard(creature: creature),
                ]
            }
            .shuffled()
    }

    private static let gameDuration = 30
    private static let pairCount = 6

    private static let fallbackCreatures: [CatchCreature] = [
        CatchCreature(id: "cat", name: "고양이", symbol: "고"),
        CatchCreature(id: "chameleon", name: "카멜레온", symbol: "카"),
        CatchCreature(id: "lizard", name: "도마뱀", symbol: "도"),
        CatchCreature(id: "tree_frog", name: "청개구리", symbol: "청"),
        CatchCreature(id: "ladybug", name: "무당벌레", symbol: "무"),
        CatchCreature(id: "sparrow", name: "참새", symbol: "참"),
    ]
}

struct CatchCard: Identifiable, Equatable {
    let id = UUID()
    let creature: CatchCreature
    var isFaceUp = false
    var isMatched = false

    var accessibilityLabel: String {
        if isMatched { return "\(creature.name) 맞춘 카드" }
        if isFaceUp { return "\(creature.name) 열린 카드" }
        return "뒤집힌 카드"
    }
}

struct CatchCreature: Identifiable, Equatable {
    let id: String
    let name: String
    let symbol: String
}

enum CatchGamePhase: Equatable {
    case loading
    case playing
    case won
    case lost

    var showsOverlay: Bool {
        self == .won || self == .lost
    }

    var title: String {
        switch self {
        case .loading, .playing:
            return ""
        case .won:
            return "congratulation!"
        case .lost:
            return "Time Over"
        }
    }

    var message: String {
        switch self {
        case .loading, .playing:
            return ""
        case .won:
            return "30초 안에 모든 생물 카드의 짝을 찾았어요."
        case .lost:
            return "시간이 끝났어요. 다시 섞어서 도전해 볼까요?"
        }
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
