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
import HomeFeature
import MinigameFeature
import DexFeature
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
        case .home:
            HomeFeature.RootView(
                collectionRepository: AppEnvironment.collection,
                sightingRepository: AppEnvironment.sightings,
                speciesRepository: AppEnvironment.species,
                locationService: AppEnvironment.location
            )
        case .feature:
            MinigameFeature.RootView(
                collectionRepository: AppEnvironment.collection,
                speciesRepository: AppEnvironment.species
            )
        case .my:
            DexFeature.RootView(
                collectionRepository: AppEnvironment.collection,
                speciesRepository: AppEnvironment.species,
                profileRepository: AppEnvironment.profile
            )
        }
    }

    // MARK: 하단 바 — Figma 133-483. 넓은 회색 프로스트 알약(선택=흰 알약 아이콘+라벨, 비선택=아이콘만) + 로고 FAB.
    private var bottomBar: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if !fabExpanded {
                HStack(spacing: 12) {
                    tabButton(.home,    title: "Home", icon: "house.fill")
                    tabButton(.feature, title: "Task", icon: "list.bullet.rectangle.fill")
                    tabButton(.my,      title: "My",   icon: "person.fill")
                }
                .frame(height: 58)
                .fixedSize(horizontal: true, vertical: false)   // 콘텐츠 폭에 고정 → 좌우 빈 여백 제거(선택 알약이 끝에 붙음)
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(Capsule().fill(tabBarFrost))
                }
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                .shadow(color: .black.opacity(0.08), radius: 10, y: 2)
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

    // Figma 133-483 회색 프로스트 그라디언트
    private var tabBarFrost: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.827, green: 0.827, blue: 0.827).opacity(0.62),
                     Color(red: 0.914, green: 0.914, blue: 0.914).opacity(0.62)],
            startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // 선택 탭 = 흰 알약(아이콘 + 라벨, 전체 높이), 비선택 = 아이콘만 (Figma 133-483).
    private func tabButton(_ tab: AppTab, title: String, icon: String) -> some View {
        let isSelected = selectedTab == tab
        return Button { selectedTab = tab } label: {
            HStack(spacing: 9) {
                Image(systemName: icon).font(.system(size: 21, weight: isSelected ? .semibold : .regular))
                if isSelected {
                    Text(title).font(.system(size: 16, weight: .medium))
                        .lineLimit(1).fixedSize()
                }
            }
            .foregroundStyle(isSelected ? .black : .black.opacity(0.45))
            .padding(.horizontal, isSelected ? 24 : 10)
            .frame(height: 58)
            .background {
                if isSelected {
                    Capsule().fill(Color.white)
                        .shadow(color: .black.opacity(0.06), radius: 4, x: -1, y: 1)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
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
            ZStack {
                if fabExpanded {
                    Image(systemName: "xmark")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(CatureColor.onFab)
                } else {
                    Image("logo")            // 추가된 로고 SVG (조리개)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .foregroundStyle(CatureColor.onFab)
                        .frame(width: 26, height: 26)
                }
            }
            .frame(width: 58, height: 58)
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
