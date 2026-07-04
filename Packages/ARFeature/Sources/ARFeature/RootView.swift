//  RootView.swift
//  ARFeature — 체험 화면(Figma 83-398): 라이브 AR + 왼쪽 종 선택 + 이름 라벨 + 뒤로. iOS 전용.

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
        if selected == nil { selected = species.first }
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
            if let selected = vm.selected {
                ARStageView(species: selected, all: vm.species) { vm.selected = $0 }
            } else {
                EmptyStateView()
            }
            if let onClose {
                Button { onClose() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 3)
                }
                .padding(.horizontal, CatureSpacing.md)
                .padding(.top, CatureSpacing.xs)
                .accessibilityLabel("닫기")
            }
        }
        .preferredColorScheme(.dark)
        .task { await vm.load() }
    }
}

private struct EmptyStateView: View {
    var body: some View {
        ZStack {
            CatureColor.darkSurface.ignoresSafeArea()
            VStack(spacing: CatureSpacing.sm) {
                Image(systemName: "cube.transparent").font(.system(size: 56, weight: .thin))
                Text("체험할 종이 아직 없어요").font(CatureFont.headline)
                Text("발견한 종 중 usdz가 있는 종만 체험할 수 있어요")
                    .font(CatureFont.caption).multilineTextAlignment(.center)
            }
            .foregroundStyle(CatureColor.darkTextSecondary)
            .padding(CatureSpacing.xl)
        }
    }
}

struct ARStageView: View {
    let species: Species
    let all: [Species]
    let onSelect: (Species) -> Void
    @State private var status: ARPlacementStatus = .findingPlane
    @State private var lowLight = false

    var body: some View {
        ZStack {
            Color(red: 0.055, green: 0.067, blue: 0.082).ignoresSafeArea()   // #0e1115
            ARExperienceView(usdzAsset: species.usdzAsset ?? "", status: $status, lowLight: $lowLight)
                .ignoresSafeArea()
                .id(species.id)   // 종 변경 시 AR 세션 새로 시작

            // 왼쪽 종 선택 리스트 (Figma)
            HStack {
                SpeciesSelector(all: all, selectedId: species.id, onSelect: onSelect)
                    .padding(.leading, CatureSpacing.md)
                Spacer()
            }

            // 상단 상태 배너 + 하단 이름 라벨
            VStack(spacing: CatureSpacing.sm) {
                banner
                if lowLight, status != .unsupported, status != .assetMissing {
                    hint("조명이 부족해요", "밝은 곳에서 더 잘 인식돼요")
                }
                Spacer()
                nameLabel.padding(.bottom, CatureSpacing.xl)
            }
            .padding(.top, CatureSpacing.xxl)
        }
    }

    private var nameLabel: some View {
        Text(species.nameKo)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Color(red: 0.157, green: 0.157, blue: 0.157), in: Capsule())   // #282828
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

struct SpeciesSelector: View {
    let all: [Species]
    let selectedId: String
    let onSelect: (Species) -> Void

    var body: some View {
        VStack(spacing: CatureSpacing.sm) {
            ForEach(all) { species in
                let isSelected = species.id == selectedId
                Button { onSelect(species) } label: {
                    Text(String(species.nameKo.prefix(1)))
                        .font(.system(size: isSelected ? 22 : 16, weight: .bold))
                        .foregroundStyle(isSelected ? CatureColor.accent : CatureColor.textSecondary)
                        .frame(width: isSelected ? 60 : 44, height: isSelected ? 60 : 44)
                        .background(CatureColor.surface, in: Circle())
                        .overlay(Circle().stroke(CatureColor.accent, lineWidth: isSelected ? 3 : 0))
                        .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(species.nameKo)
            }
        }
    }
}

#Preview {
    RootView(dependencies: .mock)
}
#endif
