//  TrueOrFalseGame.swift
//  Cature — 미니게임 "True or False" 공존 퀴즈 (찬희 S5 대체분, 승아 이관).
//
//  발견한 생물의 공존 카드(LLMService.coexistCard)에서
//   · needs(필요한 것)        → "필요해요" 문장 = 정답 O
//   · disturbances(조심할 것)  → "도움이 돼요" 문장 = 정답 X (실제론 방해가 되는 행동)
//  를 O/X 문제로 만들어, 플레이어가 공존 행동을 제대로 배웠는지 확인한다.
//
//  데이터는 CorePackage 프로토콜로만. 게임 상태는 이 패키지 내부에서만 관리(코어 오염 금지).

import CorePackage
import Foundation
import SwiftUI

// MARK: - 게임 화면

struct TrueOrFalseGameView: View {
    @StateObject private var viewModel: TrueOrFalseViewModel
    @Environment(\.dismiss) private var dismiss

    init(
        collectionRepository: any CollectionRepository,
        speciesRepository: any SpeciesRepository,
        llmService: any LLMService
    ) {
        _viewModel = StateObject(
            wrappedValue: TrueOrFalseViewModel(
                collectionRepository: collectionRepository,
                speciesRepository: speciesRepository,
                llmService: llmService
            )
        )
    }

    var body: some View {
        TrueOrFalseContentView(viewModel: viewModel)
            .task { await viewModel.load() }
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.black)
                    }
                    .accessibilityLabel("뒤로")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            #endif
    }
}

struct TrueOrFalseContentView: View {
    @ObservedObject var viewModel: TrueOrFalseViewModel

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    switch viewModel.phase {
                    case .loading:
                        loadingCard
                    case .playing:
                        if let question = viewModel.currentQuestion {
                            questionCard(question)
                            answerButtons
                        }
                    case .finished:
                        Color.clear.frame(height: 1)   // 결과는 오버레이로
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }

            if viewModel.phase == .finished {
                resultOverlay
            }
        }
        .background(.background)
        .animation(.easeInOut(duration: 0.2), value: viewModel.currentIndex)
        .animation(.easeInOut(duration: 0.2), value: viewModel.feedback)
        .animation(.easeInOut(duration: 0.2), value: viewModel.phase)
    }

    // MARK: 헤더 (제목 + 진행/점수)

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("True or False")
                    .font(.largeTitle.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text("공존 행동이 맞으면 O, 아니면 X를 골라요")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if viewModel.phase != .loading {
                HStack(spacing: 10) {
                    StatPill(title: "문제", value: viewModel.progressLabel)
                    StatPill(title: "점수", value: "\(viewModel.score)")
                }
            }
        }
    }

    private var loadingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("퀴즈를 준비하고 있어요…")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: 문제 카드

    private func questionCard(_ question: QuizQuestion) -> some View {
        VStack(spacing: 14) {
            Text(question.speciesName)
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            Text(question.statement)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let feedback = viewModel.feedback {
                Label(
                    feedback.isCorrect ? "정답이에요!" : "아쉬워요",
                    systemImage: feedback.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill"
                )
                .font(.subheadline.bold())
                .foregroundStyle(feedback.isCorrect ? .green : .red)
                .transition(.opacity)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(feedbackBorderColor, lineWidth: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(question.speciesName). \(question.statement)")
    }

    private var feedbackBorderColor: Color {
        guard let feedback = viewModel.feedback else { return .clear }
        return feedback.isCorrect ? .green : .red
    }

    // MARK: O / X 버튼

    private var answerButtons: some View {
        HStack(spacing: 16) {
            answerButton(isTrue: true, title: "맞아요", symbol: "circle", tint: .blue)
            answerButton(isTrue: false, title: "아니에요", symbol: "xmark", tint: .red)
        }
        .disabled(viewModel.feedback != nil)
    }

    private func answerButton(isTrue: Bool, title: String, symbol: String, tint: Color) -> some View {
        Button {
            viewModel.answer(isTrue)
        } label: {
            VStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 40, weight: .bold))
                Text(title)
                    .font(.headline)
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(tint.opacity(0.35), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(isTrue ? "O" : "X")")
    }

    // MARK: 결과 오버레이

    private var resultOverlay: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: viewModel.isPerfect ? "star.circle.fill" : "checkmark.seal.fill")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(viewModel.isPerfect ? .yellow : .green)

                Text(viewModel.resultTitle)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text(viewModel.resultMessage)
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

// MARK: - ViewModel

@MainActor
final class TrueOrFalseViewModel: ObservableObject {
    @Published private(set) var questions: [QuizQuestion] = []
    @Published private(set) var currentIndex = 0
    @Published private(set) var score = 0
    @Published private(set) var phase: QuizPhase = .loading
    @Published private(set) var feedback: QuizFeedback?

    private let collectionRepository: any CollectionRepository
    private let speciesRepository: any SpeciesRepository
    private let llmService: any LLMService
    private var pool: [QuizQuestion] = []

    init(
        collectionRepository: any CollectionRepository,
        speciesRepository: any SpeciesRepository,
        llmService: any LLMService
    ) {
        self.collectionRepository = collectionRepository
        self.speciesRepository = speciesRepository
        self.llmService = llmService
    }

    var currentQuestion: QuizQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var progressLabel: String {
        "\(min(currentIndex + 1, questions.count))/\(questions.count)"
    }

    var isPerfect: Bool {
        !questions.isEmpty && score == questions.count
    }

    var resultTitle: String {
        isPerfect ? "완벽해요!" : "퀴즈 끝!"
    }

    var resultMessage: String {
        "\(questions.count)문제 중 \(score)개를 맞혔어요."
    }

    func load() async {
        guard phase == .loading else { return }

        let chosen = (try? await quizSpecies()) ?? []
        var built: [QuizQuestion] = []
        for species in chosen {
            if let card = try? await llmService.coexistCard(speciesId: species.id) {
                built.append(contentsOf: Self.questions(species: species, card: card))
            }
        }

        pool = built.isEmpty ? Self.fallbackQuestions : built
        startRound()
    }

    func answer(_ value: Bool) {
        guard phase == .playing, feedback == nil, let question = currentQuestion else { return }

        let isCorrect = value == question.answer
        if isCorrect { score += 1 }
        feedback = QuizFeedback(isCorrect: isCorrect)

        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 700_000_000)
            self?.advance()
        }
    }

    func restart() {
        startRound()
    }

    private func advance() {
        feedback = nil
        if currentIndex + 1 < questions.count {
            currentIndex += 1
        } else {
            phase = .finished
        }
    }

    private func startRound() {
        questions = Array(pool.shuffled().prefix(Self.questionCount))
        currentIndex = 0
        score = 0
        feedback = nil
        phase = questions.isEmpty ? .finished : .playing
    }

    /// 발견한 종 우선(없으면 마스터 앞부분)으로 퀴즈에 쓸 종을 소수로 추린다.
    private func quizSpecies() async throws -> [Species] {
        let allSpecies = try await speciesRepository.allSpecies()
        let entries = try await collectionRepository.allEntries()
        let discoveredIDs = Set(entries.filter(\.discovered).map(\.speciesId))

        let discovered = allSpecies.filter { discoveredIDs.contains($0.id) }
        let source = discovered.isEmpty ? allSpecies : discovered
        return Array(source.prefix(Self.maxQuizSpecies))
    }

    private static func questions(species: Species, card: CoexistCard) -> [QuizQuestion] {
        let needs = card.needs.map {
            QuizQuestion(
                speciesName: species.nameKo,
                statement: "\(species.nameKo)에게 ‘\($0)’ — 필요해요.",
                answer: true
            )
        }
        let disturbances = card.disturbances.map {
            QuizQuestion(
                speciesName: species.nameKo,
                statement: "\(species.nameKo)에게 ‘\($0)’ — 도움이 돼요.",
                answer: false
            )
        }
        return needs + disturbances
    }

    private static let questionCount = 7
    private static let maxQuizSpecies = 4

    /// 데이터를 못 불러왔을 때도 게임이 돌도록 하는 최소 문제 세트.
    private static let fallbackQuestions: [QuizQuestion] = [
        QuizQuestion(speciesName: "고양이", statement: "고양이에게 ‘깨끗한 물과 먹이’ — 필요해요.", answer: true),
        QuizQuestion(speciesName: "고양이", statement: "고양이에게 ‘큰 소리로 놀래기’ — 도움이 돼요.", answer: false),
        QuizQuestion(speciesName: "카멜레온", statement: "카멜레온에게 ‘몸을 숨길 은신처’ — 필요해요.", answer: true),
        QuizQuestion(speciesName: "카멜레온", statement: "카멜레온에게 ‘손으로 만지기’ — 도움이 돼요.", answer: false),
        QuizQuestion(speciesName: "청개구리", statement: "청개구리에게 ‘안전한 서식 공간’ — 필요해요.", answer: true),
        QuizQuestion(speciesName: "청개구리", statement: "청개구리에게 ‘서식지 훼손’ — 도움이 돼요.", answer: false),
    ]
}

// MARK: - 모델

struct QuizQuestion: Identifiable, Equatable {
    let id = UUID()
    let speciesName: String
    let statement: String
    let answer: Bool   // true = 맞는(필요한) 행동
}

struct QuizFeedback: Equatable {
    let isCorrect: Bool
}

enum QuizPhase: Equatable {
    case loading
    case playing
    case finished
}

#if !CLI_BUILD
#Preview("True or False") {
    NavigationStack {
        TrueOrFalseGameView(
            collectionRepository: MockCollectionRepository(),
            speciesRepository: MockSpeciesRepository(),
            llmService: MockLLMService()
        )
    }
}
#endif
