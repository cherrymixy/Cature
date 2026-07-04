//  TrueOrFalseGame.swift
//  Cature — 미니게임 "True or False" OX 퀴즈 (Figma Lab Void, 카멜레온 3문제 데모).
//
//  흐름: 인트로 → Q1/Q2/Q3(문제·O/X·힌트) → 정답/오답 피드백 → 점수별 결과.
//  좌표는 Figma WF_MiniGame 393×852 프레임 기준 절대 배치.

import SwiftUI

// MARK: - 데이터

struct TFQuestion {
    let text: String        // 2줄
    let answer: Bool        // true = 맞아요(O), false = 아니예요(X)
    let hint: String
    let explanation: String
}

enum TFQuiz {
    static let questions: [TFQuestion] = [
        TFQuestion(
            text: "카멜레온에게는 올라갈 수 있는\n나뭇가지나 구조물이 필요하다.",
            answer: true,
            hint: "카멜레온은 주로 나뭇가지 위를 이동하며 생활해요.",
            explanation: "카멜레온은 나뭇가지 위를 이동하며 생활하기 때문에, 위아래로 움직일 수 있는 입체적인 공간이 필요해요."
        ),
        TFQuestion(
            text: "카멜레온에게는 숨을 수 있는\n잎과 은신처가 필요하다.",
            answer: true,
            hint: "카멜레온은 몸을 숨길 수 있는 공간이 있을 때 더 안정감을 느껴요.",
            explanation: "잎과 은신처는 카멜레온이 몸을 숨기고 안정감을 느끼는 데 중요한 환경 조건이에요."
        ),
        TFQuestion(
            text: "카멜레온을 발견하면 손으로 만져서\n가까이 확인해도 괜찮다.",
            answer: false,
            hint: "카멜레온은 갑작스러운 접촉에 스트레스를 받을 수 있어요.",
            explanation: "손으로 만지는 행동은 카멜레온에게 스트레스를 줄 수 있기 때문에, 거리 두고 조용히 관찰하는 것이 좋아요."
        ),
    ]
}

// MARK: - ViewModel

@MainActor
final class TrueOrFalseViewModel: ObservableObject {
    enum Phase: Equatable { case intro, question, feedback, result }

    @Published var phase: Phase = .intro
    @Published var index = 0
    @Published var showHint = false
    @Published private(set) var lastAnswer = true
    @Published private(set) var score = 0

    let questions = TFQuiz.questions

    var current: TFQuestion { questions[index] }
    var isLast: Bool { index == questions.count - 1 }
    var lastCorrect: Bool { lastAnswer == current.answer }

    var progress: Double {
        switch phase {
        case .intro:    return 0
        case .question: return (Double(index) + 0.5) / Double(questions.count)
        case .feedback: return (Double(index) + 1) / Double(questions.count)
        case .result:   return 1
        }
    }

    func start() { index = 0; score = 0; showHint = false; phase = .question }
    func answer(_ a: Bool) {
        lastAnswer = a
        if a == current.answer { score += 1 }
        phase = .feedback
    }
    func next() {
        if isLast { phase = .result }
        else { index += 1; showHint = false; phase = .question }
    }
}

// MARK: - 진입 (fullScreenCover에서 표시)

struct TrueOrFalseRootView: View {
    let onClose: () -> Void
    @StateObject private var vm = TrueOrFalseViewModel()

    var body: some View {
        ZStack {
            switch vm.phase {
            case .intro:
                TFIntroView(onStart: { vm.start() }, onBack: onClose)
            case .question:
                TFQuestionView(vm: vm, onBack: onClose)
            case .feedback:
                TFFeedbackView(vm: vm, onBack: onClose)
            case .result:
                TFResultView(vm: vm, onClose: onClose)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.949))
        .animation(.easeInOut(duration: 0.2), value: vm.phase)
    }
}

// MARK: - 팔레트

private enum TF {
    static let bg = Color(white: 0.949)                          // #f2f2f2
    static let lime = Color(red: 0.949, green: 1.0, blue: 0.318) // #f2ff51
    static let track = Color(white: 0.851)                       // #d9d9d9
    static let blue = Color(red: 0.196, green: 0.400, blue: 1.0) // #3266FF
    static let red = Color(red: 1.0, green: 0.263, blue: 0.263)  // #FF4343
    static let redLabel = Color(red: 1.0, green: 0.376, blue: 0.376) // #ff6060
    static let ink = Color(white: 0.157)                         // #282828
    static let grayChip = Color(white: 0.894)                    // #E4E4E4
    static let explain = Color(white: 0.541)                     // #8a8a8a
    static let back = Color(white: 0.42)                         // #6B6B6B
}

// MARK: - 공용 컴포넌트

/// 뒤로 버튼 (38, 63)
private func tfBackButton(_ action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Image(systemName: "chevron.left")
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(TF.back)
            .frame(width: 30, height: 30, alignment: .leading)
    }
    .accessibilityLabel("뒤로가기")
    .offset(x: 33, y: 57)
}

/// 진행 바 (흰 알약 325×45 @top113 + 회색 트랙 + 라임 진행)
private struct QuizProgressBar: View {
    let progress: Double
    var body: some View {
        ZStack(alignment: .topLeading) {
            Capsule().fill(.white).frame(width: 325, height: 45)
            Capsule().fill(TF.track).frame(width: 277, height: 11).offset(x: 24, y: 17)
            Capsule().fill(TF.lime)
                .frame(width: max(0, 277 * min(1, max(0, progress))), height: 11)
                .offset(x: 24, y: 17)
        }
        .frame(width: 325, height: 45)
    }
}

/// Q 뱃지 (검정 알약 + 라임 Josefin 텍스트)
private struct QBadge: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 24, weight: .semibold))
            .tracking(-0.96)
            .foregroundStyle(TF.lime)
            .padding(.horizontal, 14)
            .frame(height: 40)
            .background(Color.black, in: Capsule())
    }
}

/// 다크 하단 버튼 (23, 741, 347.97×56)
private struct TFBottomButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .tracking(-0.16)
                .foregroundStyle(.white)
                .frame(width: 347.97, height: 56.084)
                .background(TF.ink, in: RoundedRectangle(cornerRadius: 15.6, style: .continuous))
        }
        .buttonStyle(.plain)
        .offset(x: 23, y: 741)
    }
}

/// 파란 O 링
private struct OMark: View {
    var lineWidth: CGFloat
    var body: some View {
        Circle().strokeBorder(TF.blue, lineWidth: lineWidth)
    }
}

/// 빨간 X
private struct XMark: View {
    var lineWidth: CGFloat
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height, m = w * 0.14
            Path { p in
                p.move(to: CGPoint(x: m, y: m)); p.addLine(to: CGPoint(x: w - m, y: h - m))
                p.move(to: CGPoint(x: w - m, y: m)); p.addLine(to: CGPoint(x: m, y: h - m))
            }
            .stroke(TF.red, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        }
    }
}

// MARK: - 인트로 (126:3009)

private struct TFIntroView: View {
    let onStart: () -> Void
    let onBack: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white

            tfBackButton(onBack)

            Text("True Or False!")
                .font(.system(size: 32, weight: .semibold))
                .tracking(-1.6)
                .foregroundStyle(.black.opacity(0.9))
                .frame(width: 393, alignment: .center)
                .offset(y: 171)

            Text("수집한 생물의 특징과 공존 방법을 OX 퀴즈로 확인해요")
                .font(.system(size: 14.56, weight: .medium))
                .tracking(-0.15)
                .foregroundStyle(.black.opacity(0.6))
                .frame(width: 393, alignment: .center)
                .offset(y: 213)

            // 큰 O/X (겹친 회색 원)
            ZStack(alignment: .topLeading) {
                Circle().fill(TF.grayChip)
                    .overlay(XMark(lineWidth: 7).padding(33))
                    .frame(width: 110, height: 110)
                    .offset(x: 179.41, y: 359)
                Circle().fill(TF.grayChip)
                    .overlay(OMark(lineWidth: 7).padding(31))
                    .frame(width: 110, height: 110)
                    .offset(x: 102, y: 359)
            }

            TFBottomButton(title: "게임 시작하기", action: onStart)
        }
        .tfScreen(background: .white)
    }
}

// MARK: - 문제 (83:800 / 126:3077)

private struct TFQuestionView: View {
    @ObservedObject var vm: TrueOrFalseViewModel
    let onBack: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            TF.bg

            tfBackButton(onBack)

            QuizProgressBar(progress: vm.progress)
                .frame(width: 393, alignment: .center)
                .offset(y: 113)

            QBadge(text: "Q\(vm.index + 1).")
                .frame(width: 393, alignment: .center)
                .offset(y: 227)

            Text(vm.current.text)
                .font(.system(size: 20, weight: .medium))
                .tracking(-0.8)
                .lineSpacing(6)
                .multilineTextAlignment(.center)
                .foregroundStyle(.black)
                .frame(width: 307, alignment: .center)
                .frame(width: 393, alignment: .center)
                .offset(y: 291)

            // 답 카드
            AnswerCard(kind: .o) { vm.answer(true) }
                .offset(x: 37, y: 419)
            AnswerCard(kind: .x) { vm.answer(false) }
                .offset(x: 208, y: 419)

            // 힌트
            if vm.showHint {
                HintBox(text: vm.current.hint)
                    .offset(x: 28, y: 670)
            } else {
                Button { vm.showHint = true } label: {
                    Text("힌트 보기")
                        .font(.system(size: 13.52, weight: .medium))
                        .foregroundStyle(Color(white: 0.596))   // #989898
                        .underline()
                }
                .buttonStyle(.plain)
                .frame(width: 393, alignment: .center)
                .offset(y: 757)
            }
        }
        .tfScreen(background: TF.bg)
    }

    /// 157×157 흰 답 카드
    struct AnswerCard: View {
        enum Kind { case o, x }
        let kind: Kind
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 25, style: .continuous).fill(.white)
                    if kind == .o {
                        OMark(lineWidth: 6).frame(width: 54, height: 54).offset(x: 52, y: 42)
                        cardLabel("맞아요")
                    } else {
                        XMark(lineWidth: 6).frame(width: 42, height: 42).offset(x: 58, y: 48)
                        cardLabel("아니예요")
                    }
                }
                .frame(width: 157, height: 157)
            }
            .buttonStyle(.plain)
        }

        private func cardLabel(_ t: String) -> some View {
            Text(t)
                .font(.system(size: 16, weight: .medium))
                .tracking(-0.64)
                .foregroundStyle(.black)
                .frame(width: 157, alignment: .center)
                .offset(y: 112)
        }
    }

    /// 힌트 박스 (라임 338×133)
    struct HintBox: View {
        let text: String
        var body: some View {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Hint!")
                        .font(.system(size: 28, weight: .semibold))
                        .tracking(-1.96)
                        .foregroundStyle(.black)
                    Text(text)
                        .font(.system(size: 14, weight: .medium))
                        .tracking(-0.7)
                        .lineSpacing(4)
                        .foregroundStyle(.black.opacity(0.5))
                        .frame(width: 167, alignment: .leading)
                }
                Spacer(minLength: 0)
                Image("success-character", bundle: .module)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 101, height: 104)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .scaleEffect(x: -1)   // 좌우 반전
            }
            .padding(.leading, 16)
            .padding(.trailing, 18)
            .padding(.top, 16)
            .padding(.bottom, 13)
            .frame(width: 338, height: 133)
            .background(
                Color(red: 0.957, green: 0.996, blue: 0.490),   // #f4fe7d
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .shadow(color: .black.opacity(0.05), radius: 3)
        }
    }
}

// MARK: - 피드백 (정답 126:3155 / 오답 126:3269)

private struct TFFeedbackView: View {
    @ObservedObject var vm: TrueOrFalseViewModel
    let onBack: () -> Void

    private var correct: Bool { vm.lastCorrect }
    private var answerIsO: Bool { vm.current.answer }   // 정답이 O인가

    var body: some View {
        ZStack(alignment: .topLeading) {
            TF.bg

            tfBackButton(onBack)

            QuizProgressBar(progress: vm.progress)
                .frame(width: 393, alignment: .center)
                .offset(y: 113)

            if correct {
                // 정답: 정답 카드 1장 (중앙, top 261)
                FeedbackCard(isO: answerIsO)
                    .frame(width: 393, alignment: .center)
                    .offset(y: 261)
            } else {
                // 오답: 내가 입력한 답(좌) / 올바른 답(우)
                FeedbackCard(isO: vm.lastAnswer)          // 내가 고른 답
                    .offset(x: 64, y: 227)
                FeedbackCard(isO: vm.current.answer)      // 올바른 답
                    .offset(x: 216, y: 227)

                Text("내가 입력한 답")
                    .font(.system(size: 16, weight: .semibold))
                    .tracking(-0.64)
                    .foregroundStyle(TF.redLabel)
                    .frame(width: 120, alignment: .center)
                    .offset(x: 60.5, y: 356)
                Text("올바른 답")
                    .font(.system(size: 16, weight: .semibold))
                    .tracking(-0.64)
                    .foregroundStyle(.black)
                    .frame(width: 120, alignment: .center)
                    .offset(x: 212.5, y: 356)
            }

            Text(correct ? "정답이에요!" : "오답이에요!")
                .font(.system(size: 24, weight: .semibold))
                .tracking(-0.96)
                .foregroundStyle(.black)
                .frame(width: 393, alignment: .center)
                .offset(y: 421)

            Text(vm.current.explanation)
                .font(.system(size: 20, weight: .medium))
                .tracking(-0.8)
                .lineSpacing(6)
                .multilineTextAlignment(.center)
                .foregroundStyle(TF.explain)
                .frame(width: 307, alignment: .center)
                .frame(width: 393, alignment: .center)
                .offset(y: 472)

            TFBottomButton(title: vm.isLast ? "퀴즈 완료!" : "다음 문제") {
                vm.next()
            }
        }
        .tfScreen(background: TF.bg)
    }

    /// 113×113 피드백 카드
    struct FeedbackCard: View {
        let isO: Bool
        var body: some View {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white)
                if isO {
                    OMark(lineWidth: 5).frame(width: 38.9, height: 38.9).offset(x: 37.4, y: 25)
                    label("맞아요")
                } else {
                    XMark(lineWidth: 5).frame(width: 30.2, height: 30.2).offset(x: 41.75, y: 29)
                    label("아니예요")
                }
            }
            .frame(width: 113, height: 113)
        }
        private func label(_ t: String) -> some View {
            Text(t)
                .font(.system(size: 16, weight: .medium))
                .tracking(-0.64)
                .foregroundStyle(.black)
                .frame(width: 113, alignment: .center)
                .offset(y: 75)
        }
    }
}

// MARK: - 결과 (126:3229 …)

private struct TFResultView: View {
    @ObservedObject var vm: TrueOrFalseViewModel
    let onClose: () -> Void

    private var r: (title: String, subtitle: String, speech: String) {
        switch vm.score {
        case 3:  return ("Excellent!", "모든 문제를 맞췄어요!", "대박~")
        case 2:  return ("Good Job!", "거의 다 맞췄어요!", "이욜~")
        case 1:  return ("Keep Going!", "조금 더 알아볼까요?", "파이팅~")
        default: return ("Try Again!", "처음부터 다시 알아볼까요?", "분발해~")
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            TF.bg
            Image("success-bg", bundle: .module)
                .resizable().scaledToFill()
                .frame(width: 393, height: 852).clipped()
                .allowsHitTesting(false)

            tfBackButton(onClose)

            QuizProgressBar(progress: 1)
                .frame(width: 393, alignment: .center)
                .offset(y: 113)

            QBadge(text: "\(vm.score)/3")
                .frame(width: 393, alignment: .center)
                .offset(y: 227)

            Text(r.title)
                .font(.system(size: 28, weight: .semibold))
                .tracking(-1.4)
                .foregroundStyle(.black)
                .frame(width: 393, alignment: .center)
                .offset(y: 282)

            Text(r.subtitle)
                .font(.system(size: 18, weight: .medium))
                .tracking(-0.72)
                .foregroundStyle(.black.opacity(0.4))
                .frame(width: 393, alignment: .center)
                .offset(y: 323)

            // 캐릭터 (118, 401) 155×164 마스크
            Color.clear
                .frame(width: 155, height: 164)
                .overlay(alignment: .topLeading) {
                    Image("success-character", bundle: .module)
                        .resizable().scaledToFill()
                        .frame(width: 218.6, height: 193.1)
                        .offset(x: -30.75, y: -12.8)
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .offset(x: 118, y: 401)

            // 말풍선 (227, 376.67)
            SpeechBubbleShape()
                .fill(Color.white)
                .overlay(
                    SpeechBubbleShape()
                        .stroke(Color(red: 0.263, green: 0.263, blue: 0.263), lineWidth: 1.5)   // #434343
                )
                .frame(width: 121, height: 70.3)
                .offset(x: 227, y: 376.67)

            Text(r.speech)
                .font(.system(size: 18, weight: .medium))
                .tracking(-0.72)
                .foregroundStyle(Color(red: 0.204, green: 0.204, blue: 0.204))   // #343434
                .offset(x: 270, y: 401)

            TFBottomButton(title: "퀴즈 완료!", action: onClose)
        }
        .tfScreen(background: TF.bg)
    }
}

// MARK: - 393×852 절대 배치 헬퍼

private extension View {
    func tfScreen(background: Color) -> some View {
        self
            .frame(width: 393, height: 852, alignment: .topLeading)
            .clipped()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(background)
            .ignoresSafeArea()
            #if os(iOS)
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            #endif
    }
}
