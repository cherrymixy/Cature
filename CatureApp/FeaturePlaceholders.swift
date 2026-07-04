//  FeaturePlaceholders.swift
//  Cature — 셸 자리표시자. 각 Feature 패키지의 RootView로 교체될 자리(S9).
//  ⚠️ 로직 없음. 팀원 패키지가 준비되면 이 뷰들을 import한 Feature 루트뷰로 대체한다.

import SwiftUI
import DesignTokens

/// 공통 자리표시자 (빈 화면 + 라벨 + 교체 안내).
private struct TabPlaceholder: View {
    let title: String
    let swapNote: String
    var appearance: CatureAppearance = .light

    var body: some View {
        ZStack {
            (appearance == .light ? CatureColor.surfaceSecondary : CatureColor.darkSurface)
                .ignoresSafeArea()
            VStack(spacing: CatureSpacing.xs) {
                Text(title)
                    .font(CatureFont.title)
                    .foregroundStyle(appearance == .light ? CatureColor.textPrimary : CatureColor.darkTextPrimary)
                Text(swapNote)
                    .font(CatureFont.caption)
                    .foregroundStyle(appearance == .light ? CatureColor.textSecondary : CatureColor.darkTextSecondary)
            }
        }
    }
}

struct HomeTabPlaceholder: View {
    var body: some View { TabPlaceholder(title: "홈 · 지도", swapNote: "→ HomeFeature.RootView (찬희)") }
}

struct FeatureTabPlaceholder: View {
    var body: some View { TabPlaceholder(title: "기능 · 미니게임", swapNote: "→ MinigameFeature.RootView (예준)") }
}

struct MyTabPlaceholder: View {
    var body: some View { TabPlaceholder(title: "마이 · 도감", swapNote: "→ DexFeature.RootView (찬희)") }
}

/// 카메라(발견) 자리표시자 — fullScreenCover로 뜬다. 다크 컨텍스트.
struct CameraPlaceholder: View {
    let onClose: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            TabPlaceholder(title: "발견 · 카메라",
                           swapNote: "→ DiscoveryFeature.RootView (승아)",
                           appearance: .dark)
            Button(action: onClose) {
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
