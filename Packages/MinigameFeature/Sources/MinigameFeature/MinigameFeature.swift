//  MinigameFeature.swift
//  Cature — 미니게임: Catch Your Card (찬희).

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
        repeating: GridItem(.flexible(), spacing: 12),
        count: 3
    )

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    gameBoard
                    retryButton
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }

            if viewModel.phase.showsOverlay {
                resultOverlay
            }
        }
        .background(.background)
        .animation(.easeInOut(duration: 0.2), value: viewModel.cards)
        .animation(.easeInOut(duration: 0.2), value: viewModel.phase)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Catch Your Card")
                        .font(.largeTitle.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text("30초 안에 같은 생물 카드를 모두 찾아요")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                TimerBadge(remainingSeconds: viewModel.remainingSeconds)
            }

            ProgressView(value: viewModel.progress)
                .tint(viewModel.remainingSeconds <= 10 ? .red : .primary)

            HStack(spacing: 10) {
                StatPill(title: "찾은 짝", value: "\(viewModel.matchedPairCount)/6")
                StatPill(title: "카드", value: "\(viewModel.cards.count)")
            }
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
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
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
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: viewModel.phase == .won ? "party.popper.fill" : "hourglass")
                    .font(.system(size: 44, weight: .bold))

                Text(viewModel.phase.title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text(viewModel.phase.message)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Button {
                    viewModel.restart()
                } label: {
                    Label("다시 도전하기", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(24)
            .frame(maxWidth: 330)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(radius: 18)
            .padding()
        }
    }
}

struct TimerBadge: View {
    let remainingSeconds: Int

    var body: some View {
        VStack(spacing: 2) {
            Text("\(remainingSeconds)")
                .font(.title.bold())
                .monospacedDigit()
            Text("sec")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .frame(width: 68, height: 68)
        .background(.thinMaterial)
        .clipShape(Circle())
        .accessibilityLabel("남은 시간 \(remainingSeconds)초")
    }
}

struct StatPill: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.bold())
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.thinMaterial)
        .clipShape(Capsule())
    }
}

struct CatchCardView: View {
    let card: CatchCard
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if card.isFaceUp || card.isMatched {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.regularMaterial)
                } else {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.primary)
                }

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(card.isMatched ? .green : .secondary, lineWidth: card.isMatched ? 2 : 1)

                if card.isFaceUp || card.isMatched {
                    VStack(spacing: 8) {
                        Text(card.creature.symbol)
                            .font(.system(size: 30, weight: .bold))

                        Text(card.creature.name)
                            .font(.caption.bold())
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .padding(8)
                } else {
                    VStack(spacing: 8) {
                        Text("C")
                            .font(.system(size: 30, weight: .bold))

                        Text("Cature")
                            .font(.caption.bold())
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(.background)
                    .padding(8)
                }
            }
            .aspectRatio(0.74, contentMode: .fit)
            .opacity(card.isMatched ? 0.68 : 1)
            .scaleEffect(card.isFaceUp || card.isMatched ? 1 : 0.98)
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
