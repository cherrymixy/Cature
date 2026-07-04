//  MinigameFeature.swift
//  Cature — 미니게임 탭. Figma "Mini Game" 선택 메뉴 → Catch the Pair(카드 매칭) 진입.
//
//  화면 구성(Figma 83:304, 393×852 프레임 기준):
//   · 제목 "Mini Game" + 안내문
//   · 게임 카드 2장 — Catch the Pair!(같은 생물 카드 찾기) / True or False(공존 퀴즈)
//   · 잠금 카드 2장 — Lv 100 / Lv 200 요구
//  하단바·상태바는 앱 셸(AppShell)이 제공하므로 여기선 콘텐츠만 그린다.

import CorePackage
import Foundation
import SwiftUI

// MARK: - 진입점

public struct RootView: View {
    private let collectionRepository: any CollectionRepository
    private let speciesRepository: any SpeciesRepository

    public init(
        collectionRepository: any CollectionRepository = MockCollectionRepository(),
        speciesRepository: any SpeciesRepository = MockSpeciesRepository()
    ) {
        self.collectionRepository = collectionRepository
        self.speciesRepository = speciesRepository
    }

    public var body: some View {
        MiniGameMenuView(
            collectionRepository: collectionRepository,
            speciesRepository: speciesRepository
        )
    }
}

// MARK: - 게임 선택 메뉴 (Figma 83:304)

struct MiniGameMenuView: View {
    let collectionRepository: any CollectionRepository
    let speciesRepository: any SpeciesRepository

    @State private var showCatchPair = false
    @State private var showComingSoon = false

    // 로고 + 본문 + 카드 4개를 한 그룹으로 세로 중앙 정렬.
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 0) {
                Image("minigame-logo", bundle: .module)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200.597, height: 34.144)
                    .accessibilityLabel("Mini Game")

                Text("발견한 생물과 함께 지내는 방법을\n간단한 게임으로 확인해요")
                    .font(.system(size: 16, weight: .medium))
                    .tracking(-0.64)
                    .lineSpacing(6)
                    .foregroundStyle(.black.opacity(0.3))
                    .padding(.top, 16)

                gamesGrid
                    .padding(.top, 40)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 25)
        .padding(.bottom, 96)   // 카드 세트를 GNB 위로 (여유 있는 간격)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .alert("준비 중이에요", isPresented: $showComingSoon) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("True or False 퀴즈는 곧 만나볼 수 있어요.")
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $showCatchPair) { catchPairFlow }
        #else
        .sheet(isPresented: $showCatchPair) { catchPairFlow }
        #endif
    }

    // 카드 2 × 2 (166×220, 11 간격)
    private let columns = [
        GridItem(.flexible(), spacing: 11),
        GridItem(.flexible(), spacing: 11),
    ]

    private var gamesGrid: some View {
        LazyVGrid(columns: columns, spacing: 11) {
            Button { showCatchPair = true } label: { PairGameCard() }
                .buttonStyle(.plain)

            Button { showComingSoon = true } label: { QuizGameCard() }
                .buttonStyle(.plain)

            LockedGameCard(levelLabel: "Lv 100 요구")
            LockedGameCard(levelLabel: "Lv 200 요구")
        }
    }

    // Catch the Pair 흐름: 시작 전 안내 → 게임. 앱 탭바 위를 덮는 전체화면.
    private var catchPairFlow: some View {
        CatchPairFlowView(
            collectionRepository: collectionRepository,
            speciesRepository: speciesRepository,
            onClose: { showCatchPair = false }
        )
    }
}

// MARK: - 게임 카드: Catch the Pair!

struct PairGameCard: View {
    var body: some View {
        GameCardContent(
            icon: { PairMarkIcon() },
            title: "Catch the\nPair!",
            copy: "같은 생물 카드를\n찾는 게임"
        )
    }
}

// MARK: - 게임 카드: True or False

struct QuizGameCard: View {
    var body: some View {
        GameCardContent(
            icon: { TrueFalseIcon() },
            title: "True or\nFalse",
            copy: "맞는 공존 행동을\n고르는 퀴즈"
        )
    }
}

/// 게임 카드 공통 뼈대(아이콘 + 타이틀 + 설명). Figma game-card 스타일.
struct GameCardContent<Icon: View>: View {
    @ViewBuilder let icon: () -> Icon
    let title: String
    let copy: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            icon()
                .frame(height: 31, alignment: .topLeading)
                .padding(.top, 27)

            Text(title)
                .font(.system(size: 24, weight: .semibold))
                .tracking(-1.68)
                .lineSpacing(2)
                .foregroundStyle(.black)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 11)

            Text(copy)
                .font(.system(size: 16, weight: .medium))
                .tracking(-0.64)
                .lineSpacing(6)
                .foregroundStyle(.black.opacity(0.3))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)

            Spacer(minLength: 0)
        }
        .padding(.leading, 20)
        .padding(.trailing, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .aspectRatio(166.0 / 220.0, contentMode: .fit)
        .background(Color(white: 0.898).opacity(0.44))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.black.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.09), radius: 15, y: 4)
    }
}

// MARK: - 잠금 카드 (Lv 요구)

struct LockedGameCard: View {
    let levelLabel: String

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(white: 0.941),   // #f0f0f0
                        Color(white: 0.906),   // #e7e7e7
                        Color(white: 0.898),   // #e5e5e5
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(maxWidth: .infinity)
            .aspectRatio(166.0 / 220.0, contentMode: .fit)
            .overlay {
                VStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 34, weight: .regular))
                        .foregroundStyle(.black.opacity(0.25))

                    Text(levelLabel)
                        .font(.system(size: 16, weight: .medium))
                        .tracking(-0.64)
                        .foregroundStyle(.black.opacity(0.2))
                }
            }
            .accessibilityElement()
            .accessibilityLabel("\(levelLabel), 잠김")
    }
}

// MARK: - 아이콘: 초록 카드 한 쌍 (Catch the Pair)

struct PairMarkIcon: View {
    private static let green = Color(red: 0.310, green: 0.706, blue: 0.439)     // #4fb470
    private static let border = Color(red: 0.929, green: 0.953, blue: 0.902)    // #edf3e6

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 2.6, style: .continuous)
                .fill(Self.green)
                .frame(width: 13.8, height: 22)
                .offset(x: 14, y: 2)

            RoundedRectangle(cornerRadius: 2.6, style: .continuous)
                .fill(Self.green)
                .overlay(
                    RoundedRectangle(cornerRadius: 2.6, style: .continuous)
                        .strokeBorder(Self.border, lineWidth: 2)
                )
                .frame(width: 13.8, height: 22)
                .rotationEffect(.degrees(-21.67))
                .offset(x: 1, y: 1)
        }
        .frame(width: 30, height: 26, alignment: .topLeading)
    }
}

// MARK: - 아이콘: O / X (True or False)

struct TrueFalseIcon: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            TrueMark()
                .frame(width: 31, height: 31)

            FalseMark()
                .frame(width: 27, height: 27)
                .offset(x: 19, y: 1)
        }
        .frame(width: 49, height: 31, alignment: .topLeading)
    }
}

private struct TrueMark: View {
    private static let fill = Color(white: 0.894)                               // #E4E4E4
    private static let ring = Color(red: 0.953, green: 0.953, blue: 0.953)      // #F3F3F3
    private static let blue = Color(red: 0.196, green: 0.400, blue: 1.0)        // #3266FF

    var body: some View {
        ZStack {
            Circle()
                .fill(Self.fill)
                .overlay(Circle().strokeBorder(Self.ring, lineWidth: 2))
                .padding(1)

            Circle()
                .strokeBorder(Self.blue, lineWidth: 2.43)
                .frame(width: 11, height: 11)
        }
    }
}

private struct FalseMark: View {
    private static let fill = Color(white: 0.894)                               // #E4E4E4
    private static let red = Color(red: 1.0, green: 0.263, blue: 0.263)         // #FF4343

    var body: some View {
        ZStack {
            Circle().fill(Self.fill)

            Path { path in
                path.move(to: CGPoint(x: 9, y: 9))
                path.addLine(to: CGPoint(x: 18, y: 18))
                path.move(to: CGPoint(x: 9, y: 18))
                path.addLine(to: CGPoint(x: 18, y: 9))
            }
            .stroke(Self.red, style: StrokeStyle(lineWidth: 2.43, lineCap: .round))
            .frame(width: 27, height: 27)
        }
    }
}

// MARK: - Catch the Pair 흐름 (안내 → 게임)

enum CatchPairRoute: Hashable {
    case game
}

struct CatchPairFlowView: View {
    let collectionRepository: any CollectionRepository
    let speciesRepository: any SpeciesRepository
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            CatchPairIntroView(onBack: onClose)
                .navigationDestination(for: CatchPairRoute.self) { route in
                    switch route {
                    case .game:
                        CatchPairGameView(
                            collectionRepository: collectionRepository,
                            speciesRepository: speciesRepository,
                            onExit: onClose
                        )
                    }
                }
        }
    }
}

// MARK: - 게임 시작 전 안내 (Figma "Catch The Pair")

struct CatchPairIntroView: View {
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color(white: 0.42))   // #6B6B6B
                            .frame(width: 44, height: 44, alignment: .leading)
                    }
                    .accessibilityLabel("뒤로가기")
                    Spacer()
                }
                .padding(.leading, 23)
                .padding(.top, 8)

                Spacer().frame(height: 64)

                Text("Catch The Pair!")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.9))
                    .scaleEffect(x: 0.9, anchor: .center)

                Text("같은 생물 카드를 기억해 짝을 맞춰요")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.black.opacity(0.6))
                    .padding(.top, 12)

                Spacer().frame(height: 56)

                cardsGrid

                Spacer(minLength: 24)

                NavigationLink(value: CatchPairRoute.game) {
                    Text("게임 시작하기")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            Color(white: 0.157),   // #282828
                            in: RoundedRectangle(cornerRadius: 15.6, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 23)
                .padding(.bottom, 24)
            }
        }
        #if os(iOS)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }

    // 2 × 2 라임 카드
    private var cardsGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                IntroCard()
                IntroCard()
            }
            HStack(spacing: 12) {
                IntroCard()
                IntroCard()
            }
        }
    }
}

/// 안내 화면의 뒷면 카드(라임 + 조리개 마크 + Cature).
struct IntroCard: View {
    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(red: 0.937, green: 0.973, blue: 0.565))   // #eff890
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(.black.opacity(0.18), lineWidth: 5)
                )

            VStack(spacing: 6) {
                CardMarkShape()
                    .fill(.black)
                    .frame(width: 29, height: 28.84)
                Text("Cature")
                    .font(.system(size: 13.875, weight: .semibold))
                    .foregroundStyle(.black)
            }
            .padding(.top, 27)
        }
        .frame(width: 89, height: 109)
        .accessibilityLabel("카드 뒷면")
    }
}

/// Cature 조리개(4-blade) 마크 — card-mark.svg 좌표 그대로.
struct CardMarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()

        // Blade 1
        p.move(to: CGPoint(x: 4.69247, y: 5.06617))
        p.addCurve(to: CGPoint(x: 12.6836, y: 2.92495),
                   control1: CGPoint(x: 6.30788, y: 2.2682),
                   control2: CGPoint(x: 9.88562, y: 1.30955))
        p.addLine(to: CGPoint(x: 15.2677, y: 4.41688))
        p.addLine(to: CGPoint(x: 9.41778, y: 14.5492))
        p.addLine(to: CGPoint(x: 6.83368, y: 13.0573))
        p.addCurve(to: CGPoint(x: 4.69247, y: 5.06617),
                   control1: CGPoint(x: 4.03572, y: 11.4419),
                   control2: CGPoint(x: 3.07706, y: 7.86413))
        p.closeSubpath()

        // Blade 2
        p.move(to: CGPoint(x: 16.1325, y: 6.80713))
        p.addCurve(to: CGPoint(x: 24.1236, y: 4.66591),
                   control1: CGPoint(x: 17.7479, y: 4.00916),
                   control2: CGPoint(x: 21.3256, y: 3.05051))
        p.addCurve(to: CGPoint(x: 26.2648, y: 12.657),
                   control1: CGPoint(x: 26.9215, y: 6.28132),
                   control2: CGPoint(x: 27.8802, y: 9.85907))
        p.addLine(to: CGPoint(x: 24.7729, y: 15.2411))
        p.addLine(to: CGPoint(x: 14.6405, y: 9.39122))
        p.closeSubpath()

        // Blade 3
        p.move(to: CGPoint(x: 24.4563, y: 23.7748))
        p.addCurve(to: CGPoint(x: 16.4652, y: 25.916),
                   control1: CGPoint(x: 22.8409, y: 26.5727),
                   control2: CGPoint(x: 19.2632, y: 27.5314))
        p.addLine(to: CGPoint(x: 13.8811, y: 24.4241))
        p.addLine(to: CGPoint(x: 19.731, y: 14.2917))
        p.addLine(to: CGPoint(x: 22.3151, y: 15.7837))
        p.addCurve(to: CGPoint(x: 24.4563, y: 23.7748),
                   control1: CGPoint(x: 25.1131, y: 17.3991),
                   control2: CGPoint(x: 26.0717, y: 20.9768))
        p.closeSubpath()

        // Blade 4
        p.move(to: CGPoint(x: 13.0574, y: 22.0337))
        p.addCurve(to: CGPoint(x: 5.06625, y: 24.1749),
                   control1: CGPoint(x: 11.442, y: 24.8317),
                   control2: CGPoint(x: 7.86421, y: 25.7903))
        p.addCurve(to: CGPoint(x: 2.92503, y: 16.1838),
                   control1: CGPoint(x: 2.26828, y: 22.5595),
                   control2: CGPoint(x: 1.30963, y: 18.9818))
        p.addLine(to: CGPoint(x: 4.41696, y: 13.5997))
        p.addLine(to: CGPoint(x: 14.5493, y: 19.4496))
        p.closeSubpath()

        let scale = CGAffineTransform(
            scaleX: rect.width / 29.1896,
            y: rect.height / 28.8409
        )
        return p.applying(scale)
    }
}

// MARK: - Catch the Pair 게임 (카드 매칭)

struct CatchPairGameView: View {
    @StateObject private var viewModel: CatchYourCardViewModel
    let onExit: () -> Void

    init(
        collectionRepository: any CollectionRepository,
        speciesRepository: any SpeciesRepository,
        onExit: @escaping () -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: CatchYourCardViewModel(
                collectionRepository: collectionRepository,
                speciesRepository: speciesRepository
            )
        )
        self.onExit = onExit
    }

    var body: some View {
        CatchYourCardView(viewModel: viewModel, onExit: onExit)
            .task {
                await viewModel.load()
            }
            #if os(iOS)
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            #endif
    }
}

// MARK: - 게임 플레이 화면 (Figma WF_MiniGame 100:1756)

struct CatchYourCardView: View {
    @ObservedObject var viewModel: CatchYourCardViewModel
    let onExit: () -> Void   // 게임 종료 → 허브로 나가기

    @State private var showExitConfirm = false
    @State private var showSuccess = false   // 승리 → 성공 페이지

    private let gridColumns = Array(
        repeating: GridItem(.flexible(), spacing: 12),
        count: 3
    )

    private static let background = Color(white: 0.949)   // #f2f2f2

    var body: some View {
        ZStack {
            Self.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        showExitConfirm = true
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color(white: 0.42))   // #6B6B6B
                            .frame(width: 44, height: 44, alignment: .leading)
                    }
                    .accessibilityLabel("뒤로 가기")
                    Spacer()
                }
                .padding(.leading, 30)
                .padding(.top, 4)

                TimerBar(progress: viewModel.progress)
                    .padding(.horizontal, 34)
                    .padding(.top, 6)

                TimeChip(text: viewModel.timeText)
                    .padding(.top, 15)

                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(viewModel.cards) { card in
                        CatchCardView(card: card) {
                            viewModel.choose(card)
                        }
                    }
                }
                .padding(.horizontal, 50)
                .padding(.top, 30)
                .accessibilityElement(children: .contain)

                Spacer(minLength: 0)
            }

            // 타임아웃(패배) 모달 (Figma 117:2652). 승리는 성공 페이지로 이동.
            if viewModel.phase == .lost {
                GameModal(
                    title: "Time Out!",
                    message: "시간이 종료되었어요!",
                    leftTitle: "다시 도전하기",
                    leftAction: { viewModel.restart() },
                    rightTitle: "미니게임 화면으로",
                    rightAction: onExit
                )
                .transition(.opacity)
            } else if showExitConfirm {
                // 중도 포기 모달
                GameModal(
                    title: "그만둘까요?",
                    message: "지금 나가면 게임이 사라져요",
                    leftTitle: "계속하기",
                    leftAction: { showExitConfirm = false },
                    rightTitle: "미니게임 화면으로",
                    rightAction: onExit,
                    onDimTap: { showExitConfirm = false }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: viewModel.cards)   // 카드 뒤집기 플립
        .animation(.easeInOut(duration: 0.2), value: viewModel.phase)
        .animation(.easeInOut(duration: 0.2), value: showExitConfirm)
        #if os(iOS)
        .onChange(of: viewModel.phase) { _, newPhase in
            if newPhase == .won { showSuccess = true }
        }
        .navigationDestination(isPresented: $showSuccess) {
            CatchPairSuccessView(
                onRetry: { showSuccess = false; viewModel.restart() },
                onHome: onExit
            )
        }
        #endif
    }
}

// MARK: - 성공 페이지 (Figma Lab Void — Congratulation!)

struct CatchPairSuccessView: View {
    let onRetry: () -> Void
    let onHome: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(white: 0.949)   // #f2f2f2

            Image("success-bg", bundle: .module)
                .resizable()
                .scaledToFill()
                .frame(width: 393, height: 852)
                .clipped()
                .allowsHitTesting(false)

            // 뒤로 (36.6, 61.3)
            Button(action: onHome) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color(white: 0.42))
                    .frame(width: 30, height: 30, alignment: .leading)
            }
            .accessibilityLabel("뒤로가기")
            .offset(x: 33, y: 54)

            // 타이틀 (top 278)
            Text("Congratulation!")
                .font(.system(size: 28, weight: .semibold))
                .tracking(-1.0)
                .foregroundStyle(.black)
                .frame(width: 393, alignment: .center)
                .offset(y: 278)

            // 부제 (top 323)
            Text("카드를 다 찾는데에 성공했어요!")
                .font(.system(size: 18, weight: .medium))
                .tracking(-0.72)
                .foregroundStyle(.black.opacity(0.4))
                .frame(width: 393, alignment: .center)
                .offset(y: 323)

            // 캐릭터 마스크 (118, 401) 155×164 · 이미지 218.6×193.1 offset(-30.75,-12.8)
            Color.clear
                .frame(width: 155, height: 164)
                .overlay(alignment: .topLeading) {
                    Image("success-character", bundle: .module)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 218.6, height: 193.1)
                        .offset(x: -30.75, y: -12.8)
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .offset(x: 118, y: 401)

            // 말풍선 (226.2, 375.9) 122.5×71.9
            SpeechBubbleShape()
                .fill(Color.white)
                .overlay(
                    SpeechBubbleShape()
                        .stroke(Color(white: 0.314), lineWidth: 1.5)   // #505050
                )
                .frame(width: 122.5, height: 71.9)
                .offset(x: 226.2, y: 375.9)

            // 말풍선 텍스트 "대박~" (271, 400)
            Text("대박~")
                .font(.system(size: 18, weight: .medium))
                .tracking(-0.72)
                .foregroundStyle(.black.opacity(0.4))
                .offset(x: 271, y: 400)

            // 버튼 (top 751): 다시 도전하기(22) / 미니게임 화면으로(201.43)
            Button(action: onRetry) { successButton("다시 도전하기") }
                .buttonStyle(.plain)
                .offset(x: 22, y: 751)

            Button(action: onHome) { successButton("미니게임 화면으로") }
                .buttonStyle(.plain)
                .offset(x: 201.43, y: 751)
        }
        .frame(width: 393, height: 852, alignment: .topLeading)
        .clipped()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.949))
        .ignoresSafeArea()
        #if os(iOS)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }

    private func successButton(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .semibold))
            .tracking(-0.16)
            .foregroundStyle(.white)
            .frame(width: 170.57, height: 56)
            .background(
                Color(white: 0.157),   // #282828
                in: RoundedRectangle(cornerRadius: 15.6, style: .continuous)
            )
    }
}

/// 말풍선 (speech.svg 좌표 그대로). 우하단 꼬리가 왼쪽 아래를 향함.
struct SpeechBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 61.2563, y: 0.75625))
        p.addCurve(to: CGPoint(x: 121.756, y: 35.9223),
                   control1: CGPoint(x: 94.6695, y: 0.75625), control2: CGPoint(x: 121.756, y: 16.5008))
        p.addCurve(to: CGPoint(x: 61.2563, y: 71.0873),
                   control1: CGPoint(x: 121.756, y: 55.3435), control2: CGPoint(x: 94.6693, y: 71.0873))
        p.addCurve(to: CGPoint(x: 23.2076, y: 63.2602),
                   control1: CGPoint(x: 46.8391, y: 71.0873), control2: CGPoint(x: 33.6012, y: 68.1534))
        p.addCurve(to: CGPoint(x: 20.9382, y: 63.4166),
                   control1: CGPoint(x: 22.4742, y: 62.915), control2: CGPoint(x: 21.613, y: 62.9675))
        p.addLine(to: CGPoint(x: 11.2108, y: 69.8903))
        p.addCurve(to: CGPoint(x: 7.89212, y: 67.0546),
                   control1: CGPoint(x: 9.30766, y: 71.1568), control2: CGPoint(x: 6.93794, y: 69.132))
        p.addLine(to: CGPoint(x: 11.8473, y: 58.4437))
        p.addCurve(to: CGPoint(x: 11.2096, y: 55.6843),
                   control1: CGPoint(x: 12.2853, y: 57.4902), control2: CGPoint(x: 12.0076, y: 56.3656))
        p.addCurve(to: CGPoint(x: 0.75625, y: 35.9223),
                   control1: CGPoint(x: 4.61315, y: 50.052), control2: CGPoint(x: 0.756387, y: 43.2496))
        p.addCurve(to: CGPoint(x: 61.2563, y: 0.75625),
                   control1: CGPoint(x: 0.75625, y: 16.5008), control2: CGPoint(x: 27.843, y: 0.75625))
        p.closeSubpath()

        let scale = CGAffineTransform(
            scaleX: rect.width / 122.512,
            y: rect.height / 71.8436
        )
        return p.applying(scale)
    }
}

// MARK: - 공용 게임 모달 (Figma 117:2652) — 애플 기본 다이얼로그 대체

struct GameModal: View {
    let title: String
    let message: String
    let leftTitle: String
    let leftAction: () -> Void
    let rightTitle: String
    let rightAction: () -> Void
    var onDimTap: (() -> Void)? = nil

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { onDimTap?() }

            VStack(spacing: 0) {
                Text(title)
                    .font(.system(size: 28, weight: .semibold))
                    .tracking(-0.6)
                    .foregroundStyle(.black)
                    .padding(.top, 40)

                Text(message)
                    .font(.system(size: 18, weight: .medium))
                    .tracking(-0.72)
                    .foregroundStyle(.black.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)

                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    modalButton(leftTitle, action: leftAction)
                    modalButton(rightTitle, action: rightAction)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 18)
            }
            .frame(maxWidth: 344)
            .frame(height: 192)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 24, y: 10)
            .padding(.horizontal, 24)
        }
    }

    private func modalButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .tracking(-0.16)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Color(white: 0.157),   // #282828
                    in: RoundedRectangle(cornerRadius: 15.6, style: .continuous)
                )
        }
        .buttonStyle(.plain)
    }
}

/// 흰 알약 + 회색 트랙 + 노란 진행바 + 스톱워치 (Figma timer-shell).
struct TimerBar: View {
    let progress: Double   // 0...1

    private static let track = Color(white: 0.851)                       // #d9d9d9
    private static let fill = Color(red: 0.949, green: 1.0, blue: 0.318) // #f2ff51

    var body: some View {
        HStack(spacing: 8) {
            Capsule()
                .fill(Self.track)
                .frame(height: 11)
                .overlay(alignment: .leading) {
                    GeometryReader { geo in
                        Capsule()
                            .fill(Self.fill)
                            .frame(width: max(0, geo.size.width * min(1, max(0, progress))))
                    }
                }

            Image(systemName: "stopwatch.fill")
                .font(.system(size: 25, weight: .medium))
                .foregroundStyle(.black)
                .frame(width: 30, height: 30)
        }
        .padding(.leading, 24)
        .padding(.trailing, 11)
        .frame(height: 45)
        .background(Capsule().fill(.white))
        .accessibilityHidden(true)
    }
}

/// "30.00" 남은 시간 칩 (Figma time-chip).
struct TimeChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 18, weight: .medium))
            .tracking(-0.72)
            .monospacedDigit()
            .foregroundStyle(.black)
            .padding(.horizontal, 12)
            .frame(minWidth: 66)
            .frame(height: 31)
            .background(Capsule().fill(.white))
            .accessibilityLabel("남은 시간 \(text)초")
    }
}

/// 작은 통계 알약 (True or False 게임에서 사용).
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

/// 카드 — 뒷면(라임 + 조리개 + Cature) / 앞면(흰 카드 + 생물 이미지 + 이름). Figma card 스타일.
struct CatchCardView: View {
    let card: CatchCard
    let action: () -> Void

    private static let lime = Color(red: 0.937, green: 0.973, blue: 0.565)   // #eff890
    private static let accent = Color(red: 0.769, green: 0.796, blue: 0.463) // #c4cb76

    private var faceUp: Bool { card.isFaceUp || card.isMatched }

    var body: some View {
        Button(action: action) {
            ZStack {
                // 뒷면 — 전반부(0~90°)에 보임
                backFace
                    .opacity(faceUp ? 0 : 1)

                // 앞면 — 후반부(90~180°)에 보임. 미러링 보정을 위해 180° 선회전.
                frontFace
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    .opacity(faceUp ? 1 : 0)
            }
            .rotation3DEffect(
                .degrees(faceUp ? 180 : 0),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.5
            )
            .aspectRatio(89.0 / 109.0, contentMode: .fit)
            .opacity(card.isMatched ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(card.isMatched)
        .accessibilityLabel(card.accessibilityLabel)
    }

    // 뒷면: 라임 + 조리개 + Cature
    private var backFace: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Self.lime)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(.black.opacity(0.18), lineWidth: 5)
                )

            VStack(spacing: 6) {
                CardMarkShape()
                    .fill(.black)
                    .frame(width: 29, height: 28.84)
                Text("Cature")
                    .font(.system(size: 13.875, weight: .semibold))
                    .foregroundStyle(.black)
            }
        }
    }

    // 앞면: 흰 카드 + 생물 이미지 + 이름
    private var frontFace: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Self.accent, lineWidth: 5)
                )

            VStack(spacing: 4) {
                creatureImage
                    .frame(height: 58)
                Text(card.creature.name)
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(-0.48)
                    .foregroundStyle(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 10)
        }
    }

    @ViewBuilder
    private var creatureImage: some View {
        if let imageName = card.creature.imageName {
            Image(imageName, bundle: .module)
                .resizable()
                .scaledToFit()
        } else {
            Text(card.creature.symbol)
                .font(.system(size: 34))
        }
    }
}

@MainActor
final class CatchYourCardViewModel: ObservableObject {
    @Published private(set) var cards: [CatchCard] = []
    @Published private(set) var remainingTime: Double = 30
    @Published private(set) var phase: CatchGamePhase = .loading

    private let collectionRepository: any CollectionRepository
    private let speciesRepository: any SpeciesRepository
    private var timerTask: Task<Void, Never>?
    private var deadline: Date?
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
        remainingTime / Self.gameDuration
    }

    /// "30.00" 형식의 남은 시간.
    var timeText: String {
        String(format: "%.2f", max(0, remainingTime))
    }

    func load() async {
        guard cards.isEmpty else { return }
        creatures = Self.themedCreatures
        restart()
    }

    func restart() {
        timerTask?.cancel()
        remainingTime = Self.gameDuration
        deadline = Date().addingTimeInterval(Self.gameDuration)
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
                try? await Task.sleep(nanoseconds: 30_000_000)   // ~0.03s → 소수점 카운트다운
                self?.tick()
            }
        }
    }

    private func tick() {
        guard phase == .playing, let deadline else { return }

        let remaining = deadline.timeIntervalSinceNow
        if remaining <= 0 {
            remainingTime = 0
            timerTask?.cancel()
            phase = cards.allSatisfy(\.isMatched) ? .won : .lost
        } else {
            remainingTime = remaining
        }
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

    private static let gameDuration: Double = 30
    private static let pairCount = 6

    // Figma WF Mini Game 덱 — 6종(닭·파리·느티나무·드라세나·카멜레온·개미) 이미지 카드.
    private static let themedCreatures: [CatchCreature] = [
        CatchCreature(id: "chicken",   name: "닭",       symbol: "🐔", imageName: "chicken"),
        CatchCreature(id: "fly",       name: "파리",     symbol: "🪰", imageName: "fly"),
        CatchCreature(id: "tree",      name: "느티나무", symbol: "🌳", imageName: "tree"),
        CatchCreature(id: "plant",     name: "드라세나", symbol: "🪴", imageName: "pot-plant"),
        CatchCreature(id: "chameleon", name: "카멜레온", symbol: "🦎", imageName: "chameleon"),
        CatchCreature(id: "ant",       name: "개미",     symbol: "🐜", imageName: "ant"),
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
    var imageName: String? = nil
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
#Preview("Mini Game 메뉴") {
    RootView(
        collectionRepository: MockCollectionRepository(),
        speciesRepository: MockSpeciesRepository()
    )
}
#endif
