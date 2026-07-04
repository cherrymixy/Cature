//  RootView.swift
//  DiscoveryFeature — 발견 플로우 진입점. .camera = 라이브 카메라 화면(Figma), 그 외 = 다크 카드 화면.

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
        Group {
            if case .camera = vm.step {
                CameraScreen(
                    controller: controller,
                    onCaptured: { url in Task { await vm.ingest(url) } },
                    onPickFallback: { Task { await vm.capture() } },
                    onClose: onClose
                )
            } else {
                ZStack(alignment: .topLeading) {
                    CatureColor.darkSurface.ignoresSafeArea()
                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(CatureSpacing.lg)
                    if let onClose {
                        Button { onClose() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(CatureColor.darkTextPrimary)
                                .padding(CatureSpacing.sm)
                        }
                        .padding(CatureSpacing.md)
                        .accessibilityLabel("닫기")
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
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
            ProgressView().tint(CatureColor.accent)
            Text("분석 중…")
                .font(CatureFont.body)
                .foregroundStyle(CatureColor.darkTextSecondary)
        }
    }
}

struct NotFoundView: View {
    let onRetake: () -> Void
    var body: some View {
        VStack(spacing: CatureSpacing.md) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 56, weight: .thin))
                .foregroundStyle(CatureColor.darkTextSecondary)
            Text("생물을 찾지 못했어요")
                .font(CatureFont.headline)
                .foregroundStyle(CatureColor.darkTextPrimary)
            Text("조금 더 가까이, 밝은 곳에서 다시 담아볼까요?")
                .font(CatureFont.caption)
                .foregroundStyle(CatureColor.darkTextSecondary)
                .multilineTextAlignment(.center)
            Button("다시 찍기") { onRetake() }
                .buttonStyle(.caturePrimary)
                .padding(.top, CatureSpacing.sm)
        }
    }
}

#Preview {
    RootView(dependencies: .mock)
}
