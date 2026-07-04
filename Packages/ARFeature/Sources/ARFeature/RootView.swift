//  RootView.swift
//  ARFeature — 체험 진입점: 체험 가능 종 선택 → AR 배치 화면(오버레이 안내). iOS 전용.

#if os(iOS)
import SwiftUI
import Observation
import CorePackage
import DesignTokens

@MainActor
@Observable
final class ARExperienceViewModel {
    private(set) var species: [Species] = []
    var selected: Species?

    private let deps: ARDependencies
    init(deps: ARDependencies) { self.deps = deps }

    func load() async {
        let collected = (try? await deps.collection.allEntries()) ?? []
        let all = (try? await deps.species.allSpecies()) ?? []
        species = experienceableSpecies(collected: collected, allSpecies: all)
    }
}

public struct RootView: View {
    @State private var vm: ARExperienceViewModel
    private let onClose: (() -> Void)?

    public init(dependencies: ARDependencies = .mock, onClose: (() -> Void)? = nil) {
        _vm = State(initialValue: ARExperienceViewModel(deps: dependencies))
        self.onClose = onClose
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            CatureColor.darkSurface.ignoresSafeArea()
            if let selected = vm.selected {
                ARContainerView(species: selected) { vm.selected = nil }
            } else {
                selectionList
            }
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
        .preferredColorScheme(.dark)
        .task { await vm.load() }
    }

    @ViewBuilder private var selectionList: some View {
        VStack(alignment: .leading, spacing: CatureSpacing.lg) {
            Text("AR로 만나기")
                .font(CatureFont.title)
                .foregroundStyle(CatureColor.darkTextPrimary)

            if vm.species.isEmpty {
                Spacer()
                VStack(spacing: CatureSpacing.sm) {
                    Image(systemName: "cube.transparent").font(.system(size: 56, weight: .thin))
                    Text("체험할 종이 아직 없어요").font(CatureFont.headline)
                    Text("발견한 종 중 usdz가 있는 종만 체험할 수 있어요")
                        .font(CatureFont.caption).multilineTextAlignment(.center)
                }
                .foregroundStyle(CatureColor.darkTextSecondary)
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                Text("수집한 종 중 체험 가능")
                    .font(CatureFont.caption)
                    .foregroundStyle(CatureColor.darkTextSecondary)
                ForEach(vm.species) { species in
                    Button { vm.selected = species } label: {
                        HStack {
                            Image(systemName: "cube.transparent").foregroundStyle(CatureColor.accent)
                            Text(species.nameKo).font(CatureFont.headline).foregroundStyle(CatureColor.darkTextPrimary)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(CatureColor.darkTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .catureCard(.dark)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
        .padding(CatureSpacing.lg)
        .padding(.top, CatureSpacing.xl)
    }
}

struct ARContainerView: View {
    let species: Species
    let onBack: () -> Void
    @State private var status: ARPlacementStatus = .findingPlane
    @State private var lowLight = false

    var body: some View {
        ZStack(alignment: .top) {
            ARExperienceView(usdzAsset: species.usdzAsset ?? "", status: $status, lowLight: $lowLight)
                .ignoresSafeArea()

            VStack(spacing: CatureSpacing.sm) {
                banner
                if lowLight && status != .unsupported && status != .assetMissing {
                    hint("조명이 부족해요", "밝은 곳에서 더 잘 인식돼요")
                }
                Spacer()
                Button("← 다른 종") { onBack() }
                    .font(CatureFont.callout)
                    .foregroundStyle(.white)
                    .padding(.horizontal, CatureSpacing.md)
                    .padding(.vertical, CatureSpacing.xs)
                    .background(.black.opacity(0.4))
                    .clipShape(Capsule())
                    .padding(.bottom, CatureSpacing.lg)
            }
            .padding(.top, CatureSpacing.xxl)
        }
    }

    @ViewBuilder private var banner: some View {
        switch status {
        case .unsupported:
            hint("이 기기는 AR을 지원하지 않아요", "실기기(iPhone)에서 체험할 수 있어요")
        case .findingPlane:
            hint("평면을 찾는 중…", "바닥이나 테이블을 천천히 비춰주세요")
        case .readyToPlace:
            hint("화면을 탭해 \(species.nameKo)를 놓아보세요", "드래그·회전·핀치로 조작")
        case .assetMissing:
            hint("체험 에셋이 없어요", "\(species.usdzAsset ?? "usdz")를 Assets3D에 추가하세요")
        case .placed:
            EmptyView()
        }
    }

    private func hint(_ title: String, _ subtitle: String?) -> some View {
        VStack(spacing: 2) {
            Text(title).font(CatureFont.headline).foregroundStyle(.white)
            if let subtitle {
                Text(subtitle).font(CatureFont.caption).foregroundStyle(.white.opacity(0.8))
            }
        }
        .multilineTextAlignment(.center)
        .padding(CatureSpacing.md)
        .background(.black.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: CatureRadius.md, style: .continuous))
    }
}

#Preview {
    RootView(dependencies: .mock)
}
#endif
