//  RootView.swift
//  DiscoveryFeature — 발견 플로우 진입점(앱 셸의 카메라 FAB가 띄운다). 다크 컨텍스트.

import SwiftUI
import DesignTokens

public struct RootView: View {
    @State private var vm: DiscoveryViewModel
    @State private var didStart = false
    private let onEnterExperience: () -> Void
    private let onClose: (() -> Void)?

    /// - onEnterExperience: 체험(AR) 진입점 라우팅 (S8 ARFeature).
    /// - onClose: 셸이 커버를 닫을 때.
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
        ZStack {
            CatureColor.darkSurface.ignoresSafeArea()
            content
                .padding(CatureSpacing.lg)
        }
        .preferredColorScheme(.dark)
        .task {
            // 발견 진입 → 커버 안정화 후 바로 카메라.
            guard !didStart else { return }
            didStart = true
            try? await Task.sleep(for: .milliseconds(350))
            if case .camera = vm.step { await vm.capture() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch vm.step {
        case .camera:
            CameraView(vm: vm, onClose: onClose)
        case .analyzing:
            AnalyzingView()
        case .candidates(let candidates):
            AnalysisView(vm: vm, candidates: candidates)
        case .notFound:
            NotFoundView(onRetake: { Task { await vm.retake() } })
        case .coexist(let card, let species, let candidate):
            CoexistCardView(vm: vm, card: card, species: species, candidate: candidate)
        case .collected(let name, let count, let rate, let canExperience):
            CollectedView(
                name: name, captureCount: count, achievement: rate,
                canExperience: canExperience,
                onExperience: onEnterExperience,
                onConfirm: { vm.reset() }
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
