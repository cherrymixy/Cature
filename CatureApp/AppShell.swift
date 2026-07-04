//  AppShell.swift
//  Cature — 하단 3탭 셸 + 카메라 스피드다이얼 FAB. 로직 없음(네비게이션 상태만).
//
//  ▼ 라우팅 교체 지점 (S9): 아래 placeholder를 각 Feature 루트뷰로 바꾼다.
//     홈     → HomeFeature.RootView       (예준)
//     기능   → MinigameFeature.RootView   (찬희)
//     마이   → DexFeature.RootView        (찬희)
//     FAB(스피드다이얼): 발견 → DiscoveryFeature.RootView / AR 체험 → ARFeature.RootView (승아)

import SwiftUI
import DesignTokens
import DiscoveryFeature
import ARFeature

enum AppTab: Hashable {
    case home, feature, my
}

struct RootView: View {
    @State private var selectedTab: AppTab = .home
    @State private var showCamera = false
    @State private var showExperience = false
    @State private var pendingExperience = false
    @State private var fabExpanded = false

    var body: some View {
        ZStack(alignment: .bottom) {
            selectedContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 스피드다이얼 확장 시 화면 프로스트 딤 (탭하면 닫힘)
            if fabExpanded {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .onTapGesture { fabExpanded = false }
                    .transition(.opacity)
            }

            bottomBar
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: fabExpanded)
        .fullScreenCover(isPresented: $showCamera, onDismiss: {
            // 카메라 커버가 닫힌 뒤 체험(AR)으로 순차 전환.
            if pendingExperience { pendingExperience = false; showExperience = true }
        }) {
            DiscoveryFeature.RootView(
                dependencies: AppEnvironment.discovery,   // 실 카메라·OpenAI·로컬저장 (키 없으면 Mock 폴백)
                onEnterExperience: { pendingExperience = true; showCamera = false },
                onClose: { showCamera = false }
            )
        }
        .fullScreenCover(isPresented: $showExperience) {
            ARFeature.RootView(
                dependencies: AppEnvironment.ar,          // 실 CollectionRepository (발견과 공유)
                onClose: { showExperience = false }
            )
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

    // MARK: 하단 바 — 알약형 탭(확장 시 숨김) + 스피드다이얼 FAB
    private var bottomBar: some View {
        HStack(alignment: .bottom, spacing: CatureSpacing.sm) {
            if !fabExpanded {
                HStack(spacing: 0) {
                    tabButton(.home,    title: "홈",   icon: "map")
                    tabButton(.feature, title: "기능", icon: "gamecontroller")
                    tabButton(.my,      title: "마이", icon: "person")
                }
                .caturePillTab(.light)     // DesignTokens PillTabStyle
                .transition(.move(edge: .leading).combined(with: .opacity))
            }

            Spacer(minLength: 0)

            // 스피드다이얼: 액션(확장 시) + FAB
            VStack(alignment: .trailing, spacing: CatureSpacing.md) {
                if fabExpanded {
                    dialAction(label: "AR 체험", icon: "cube.transparent") {
                        fabExpanded = false
                        showExperience = true
                    }
                    dialAction(label: "발견", icon: "camera.fill") {
                        fabExpanded = false
                        showCamera = true
                    }
                }
                fab
            }
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

    // 스피드다이얼 액션(라벨 + 원형 아이콘 버튼)
    private func dialAction(label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: CatureSpacing.sm) {
                Text(label)
                    .font(CatureFont.headline)
                    .foregroundStyle(CatureColor.textPrimary)
                    .padding(.horizontal, CatureSpacing.sm)
                    .padding(.vertical, 6)
                    .background(CatureColor.surface, in: Capsule())
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(CatureColor.accent)
                    .frame(width: 52, height: 52)
                    .background(CatureColor.surface, in: Circle())
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
            }
        }
        .buttonStyle(.plain)
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }

    private var fab: some View {
        Button { fabExpanded.toggle() } label: {
            Image(systemName: fabExpanded ? "xmark" : "camera.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(CatureColor.onFab)
                .frame(width: 56, height: 56)
                .background(CatureColor.fab, in: Circle())
                .rotationEffect(.degrees(fabExpanded ? 90 : 0))
                .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(fabExpanded ? "닫기" : "카메라")
    }
}

#Preview {
    RootView()
}
