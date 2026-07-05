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
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 3)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .padding(.leading, CatureSpacing.xs)
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

            // 상단 가이드 pill (Figma 118:818)
            VStack {
                guidancePill
                Spacer()
            }
            .padding(.top, 62)
        }
    }

    // 흰 반투명 pill 안내 (Figma: 평면 위를 클릭해 배치해 보세요!)
    @ViewBuilder private var guidancePill: some View {
        if let text = guidanceText {
            Text(text)
                .font(.system(size: 16))
                .tracking(-0.8)
                .foregroundStyle(Color(white: 0.478))   // #7a7a7a
                .padding(.horizontal, 20)
                .frame(height: 38)
                .background(Color.white.opacity(0.85), in: Capsule())
                .overlay(Capsule().stroke(.black.opacity(0.05)))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
        }
    }

    private var guidanceText: String? {
        switch status {
        case .findingPlane, .readyToPlace: return "평면 위를 클릭해 배치해 보세요!"
        case .unsupported:                 return "이 기기는 AR을 지원하지 않아요"
        case .assetMissing:                return "체험 에셋이 없어요"
        case .placed:                      return lowLight ? "조명이 부족해요, 밝은 곳에서 더 잘 보여요" : nil
        }
    }
}

struct SpeciesSelector: View {
    let all: [Species]
    let selectedId: String
    let onSelect: (Species) -> Void

    var body: some View {
        VStack(spacing: 14) {
            ForEach(all) { species in
                let isSelected = species.id == selectedId
                Button { onSelect(species) } label: {
                    Text(String(species.nameKo.prefix(1)))
                        .font(.system(size: isSelected ? 24 : 17, weight: .bold))
                        .foregroundStyle(isSelected ? .black : .black.opacity(0.5))
                        .frame(width: isSelected ? 72 : 51, height: isSelected ? 72 : 51)
                        .background(isSelected ? CatureColor.lime : Color.white, in: Circle())
                        .shadow(color: .black.opacity(0.18), radius: 6, y: 2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(species.nameKo)
            }

            // 더보기 (Figma) — 다크 원형
            ZStack {
                Circle().fill(Color(white: 0.157))
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 51, height: 51)
        }
    }
}

#Preview {
    RootView(dependencies: .mock)
}
#endif
