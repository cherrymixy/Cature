//  RootView.swift
//  DiscoveryFeature — 발견 플로우 진입점. .camera = 라이브 카메라(다크), 그 외 = 라이트 카드(Figma).

import SwiftUI
import DesignTokens

public struct RootView: View {
    @State private var vm: DiscoveryViewModel
    @State private var controller = CameraController()
    private let onEnterExperience: () -> Void
    private let onClose: (() -> Void)?

    public init(
        dependencies: DiscoveryDependencies = .mock,
        onEnterExperience: @escaping () -> Void = {},
        onClose: (() -> Void)? = nil
    ) {
        _vm = State(initialValue: DiscoveryViewModel(deps: dependencies))
        self.onEnterExperience = onEnterExperience
        self.onClose = onClose
    }

    public var body: some View {
        if case .camera = vm.step {
            CameraScreen(
                controller: controller,
                onCaptured: { url in Task { await vm.ingest(url) } },
                onPickFallback: { Task { await vm.capture() } },
                onClose: onClose
            )
            .preferredColorScheme(.dark)
        } else {
            ZStack {
                CatureColor.surface.ignoresSafeArea()
                VStack(spacing: 0) {
                    backBar
                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .preferredColorScheme(.light)
        }
    }

    private var backBar: some View {
        HStack {
            Button { handleBack() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("뒤로")
            Spacer()
        }
        .padding(.leading, CatureSpacing.xs)
    }

    /// 뒤로: 공존카드→후보, 수집→닫기, 그 외(분석/분석중/실패)→카메라.
    private func handleBack() {
        switch vm.step {
        case .coexist:   vm.backToCandidates()
        case .collected: onClose?()
        default:         vm.retake()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch vm.step {
        case .camera:
            EmptyView()   // 위에서 CameraScreen으로 처리
        case .analyzing:
            AnalyzingView()
        case .candidates(let candidates):
            AnalysisView(vm: vm, candidates: candidates)
        case .notFound:
            NotFoundView(onRetake: { vm.retake() })
        case .coexist(let card, let species, let candidate):
            CoexistCardView(vm: vm, card: card, species: species, candidate: candidate)
        case .collected(let name, let count, let rate, let canExperience):
            CollectedView(
                name: name, captureCount: count, achievement: rate,
                canExperience: canExperience,
                onExperience: onEnterExperience,
                onConfirm: { onClose?() }
            )
        }
    }
}

struct AnalyzingView: View {
    var body: some View {
        VStack(spacing: CatureSpacing.md) {
            ProgressView().tint(Color.gray)   // 라이트 배경에 포인트(라임)는 안 보여 그레이로
            Text("분석 중…")
                .font(CatureFont.body)
                .foregroundStyle(.black.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NotFoundView: View {
    let onRetake: () -> Void
    var body: some View {
        VStack(spacing: CatureSpacing.md) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 56, weight: .thin))
                .foregroundStyle(.black.opacity(0.35))
            Text("생물을 찾지 못했어요")
                .font(CatureFont.headline)
                .foregroundStyle(.black)
            Text("조금 더 가까이, 밝은 곳에서 다시 담아볼까요?")
                .font(CatureFont.caption)
                .foregroundStyle(.black.opacity(0.5))
                .multilineTextAlignment(.center)
            Button("다시 찍기") { onRetake() }
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, CatureSpacing.lg)
                .frame(height: 52)
                .background(CatureColor.ink, in: Capsule())
                .padding(.top, CatureSpacing.sm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(CatureSpacing.lg)
    }
}

#Preview {
    RootView(dependencies: .mock)
}
