//  AppShell.swift
//  Cature — 하단 3탭 셸 + 카메라 FAB. 로직 없음(네비게이션 상태만).
//
//  ▼ 라우팅 교체 지점 (S9): 아래 placeholder를 각 Feature 루트뷰로 바꾼다.
//     홈     → HomeFeature.RootView       (찬희)
//     기능   → MinigameFeature.RootView   (예준)
//     마이   → DexFeature.RootView        (찬희)
//     카메라 → DiscoveryFeature.RootView  (승아)

import SwiftUI
import DesignTokens

enum AppTab: Hashable {
    case home, feature, my
}

struct RootView: View {
    @State private var selectedTab: AppTab = .home
    @State private var showCamera = false

    var body: some View {
        ZStack(alignment: .bottom) {
            selectedContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            bottomBar
        }
        .fullScreenCover(isPresented: $showCamera) {
            // 라우팅 교체 지점 → DiscoveryFeature.RootView (승아)
            CameraPlaceholder { showCamera = false }
        }
    }

    // MARK: 탭 콘텐츠 (라우팅 교체 지점)
    @ViewBuilder
    private var selectedContent: some View {
        switch selectedTab {
        case .home:    HomeTabPlaceholder()
        case .feature: FeatureTabPlaceholder()
        case .my:      MyTabPlaceholder()
        }
    }

    // MARK: 하단 바 — 알약형 탭 + 다크 원형 카메라 FAB
    private var bottomBar: some View {
        HStack(spacing: CatureSpacing.sm) {
            HStack(spacing: 0) {
                tabButton(.home,    title: "홈",   icon: "map")
                tabButton(.feature, title: "기능", icon: "gamecontroller")
                tabButton(.my,      title: "마이", icon: "person")
            }
            .caturePillTab(.light)     // DesignTokens PillTabStyle

            cameraFAB
        }
        .padding(.horizontal, CatureSpacing.md)
        .padding(.bottom, CatureSpacing.xs)
    }

    private func tabButton(_ tab: AppTab, title: String, icon: String) -> some View {
        Button { selectedTab = tab } label: {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 18, weight: .semibold))
                Text(title).font(CatureFont.caption)
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(selectedTab == tab ? CatureColor.accent : CatureColor.textSecondary)
        }
        .buttonStyle(.plain)
    }

    private var cameraFAB: some View {
        Button { showCamera = true } label: {
            Image(systemName: "camera.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(CatureColor.onFab)
                .frame(width: 56, height: 56)
                .background(CatureColor.fab)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("카메라")
    }
}

#Preview {
    RootView()
}
