//  OnboardingFeature.swift
//  Cature — 온보딩·Auth (예준 S1, 승아 이관).
//
//  플로우: 4스텝 소개 슬라이드 → 권한 안내(문구만) → 프로필(닉네임·@아이디) 저장 → onComplete.
//  · 실제 카메라/위치 권한 요청은 승아의 서비스가 담당(여기선 안내 카피만).
//  · 데이터는 CorePackage 프로토콜(ProfileRepository)로만, 스타일은 DesignTokens로만.

import CorePackage
import DesignTokens
import SwiftUI

// MARK: - 진입점

public struct RootView: View {
    private let profileRepository: any ProfileRepository
    private let onComplete: () -> Void

    @State private var phase: OnboardingPhase = .slides

    public init(
        profileRepository: any ProfileRepository = MockProfileRepository(),
        onComplete: @escaping () -> Void = {}
    ) {
        self.profileRepository = profileRepository
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            CatureColor.surface.ignoresSafeArea()
            content
                .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.25), value: phase)
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .slides:
            OnboardingSlidesView(onFinish: { phase = .permissions })
        case .permissions:
            OnboardingPermissionsView(onContinue: { phase = .auth })
        case .auth:
            OnboardingAuthView(profileRepository: profileRepository, onComplete: onComplete)
        }
    }
}

enum OnboardingPhase: Equatable {
    case slides
    case permissions
    case auth
}

// MARK: - 소개 슬라이드

struct OnboardingSlide: Identifiable {
    let id: Int
    let symbol: String
    let title: String
    let detail: String

    static let all: [OnboardingSlide] = [
        OnboardingSlide(
            id: 0,
            symbol: "binoculars.fill",
            title: "주변의 생물을 발견해요",
            detail: "산책길에서 마주친 생물을 카메라로 담아 보세요."
        ),
        OnboardingSlide(
            id: 1,
            symbol: "sparkle.magnifyingglass",
            title: "이 생명을 알아봐요",
            detail: "찍은 사진을 분석해 어떤 생명인지 알려드려요."
        ),
        OnboardingSlide(
            id: 2,
            symbol: "leaf.fill",
            title: "필요한 것과 방해를 알게 돼요",
            detail: "이 생명에게 필요한 것과, 사람이 조심할 행동을 함께 봐요."
        ),
        OnboardingSlide(
            id: 3,
            symbol: "square.grid.2x2.fill",
            title: "도감·지도에 수집하고 체험해요",
            detail: "발견한 생명을 도감과 지도에 모으고 AR로 만나요."
        ),
    ]
}

struct OnboardingSlidesView: View {
    let onFinish: () -> Void

    @State private var index = 0
    private let slides = OnboardingSlide.all

    private var isLast: Bool { index == slides.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            skipBar
            pager
            pageDots
                .padding(.bottom, CatureSpacing.lg)
            nextButton
                .padding(.horizontal, CatureSpacing.lg)
                .padding(.bottom, CatureSpacing.lg)
        }
    }

    private var skipBar: some View {
        HStack {
            Spacer()
            Button("건너뛰기") { onFinish() }
                .font(CatureFont.callout)
                .foregroundStyle(CatureColor.textSecondary)
                .opacity(isLast ? 0 : 1)
                .disabled(isLast)
                .accessibilityHidden(isLast)
        }
        .frame(height: 44)
        .padding(.horizontal, CatureSpacing.lg)
    }

    private var pager: some View {
        TabView(selection: $index) {
            ForEach(slides) { slide in
                OnboardingSlideView(slide: slide)
                    .tag(slide.id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private var pageDots: some View {
        HStack(spacing: CatureSpacing.xs) {
            ForEach(slides) { slide in
                Capsule()
                    .fill(slide.id == index ? CatureColor.accent : CatureColor.surfaceSecondary)
                    .frame(width: slide.id == index ? 22 : 8, height: 8)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: index)
        .accessibilityHidden(true)
    }

    private var nextButton: some View {
        Button(isLast ? "시작하기" : "다음") {
            if isLast {
                onFinish()
            } else {
                withAnimation { index += 1 }
            }
        }
        .buttonStyle(.caturePrimary)
    }
}

struct OnboardingSlideView: View {
    let slide: OnboardingSlide

    var body: some View {
        VStack(spacing: CatureSpacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(CatureColor.accentSoft)
                    .frame(width: 168, height: 168)
                Image(systemName: slide.symbol)
                    .font(.system(size: 68, weight: .medium))
                    .foregroundStyle(CatureColor.accent)
            }
            .accessibilityHidden(true)

            VStack(spacing: CatureSpacing.sm) {
                Text(slide.title)
                    .font(CatureFont.title)
                    .foregroundStyle(CatureColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text(slide.detail)
                    .font(CatureFont.body)
                    .foregroundStyle(CatureColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, CatureSpacing.xl)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 권한 안내 (문구만; 실제 요청은 승아 서비스)

struct OnboardingPermissionsView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: CatureSpacing.lg) {
            VStack(alignment: .leading, spacing: CatureSpacing.xs) {
                Text("시작하기 전에")
                    .font(CatureFont.largeTitle)
                    .foregroundStyle(CatureColor.textPrimary)
                Text("Cature는 이런 순간에만 권한을 요청해요.")
                    .font(CatureFont.body)
                    .foregroundStyle(CatureColor.textSecondary)
            }
            .padding(.top, CatureSpacing.xl)

            OnboardingPermissionRow(
                symbol: "camera.fill",
                title: "카메라",
                detail: "생물을 촬영해 발견할 때 사용해요."
            )
            OnboardingPermissionRow(
                symbol: "location.fill",
                title: "위치",
                detail: "발견한 장소를 지도에 남길 때 사용해요."
            )

            HStack(alignment: .top, spacing: CatureSpacing.xs) {
                Image(systemName: "info.circle")
                Text("권한은 실제로 필요한 순간에 물어봐요. 언제든 설정에서 바꿀 수 있어요.")
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(CatureFont.caption)
            .foregroundStyle(CatureColor.textSecondary)

            Spacer()

            Button("계속") { onContinue() }
                .buttonStyle(.caturePrimary)
        }
        .padding(.horizontal, CatureSpacing.lg)
        .padding(.bottom, CatureSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct OnboardingPermissionRow: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: CatureSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: CatureRadius.md, style: .continuous)
                    .fill(CatureColor.accentSoft)
                    .frame(width: 52, height: 52)
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(CatureColor.accent)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(CatureFont.headline)
                    .foregroundStyle(CatureColor.textPrimary)
                Text(detail)
                    .font(CatureFont.callout)
                    .foregroundStyle(CatureColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("온보딩 전체") {
    RootView(profileRepository: MockProfileRepository())
}

#Preview("슬라이드") {
    OnboardingSlidesView(onFinish: {})
}

#Preview("권한 안내") {
    OnboardingPermissionsView(onContinue: {})
}
