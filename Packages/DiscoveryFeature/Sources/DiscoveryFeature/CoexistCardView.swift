//  CoexistCardView.swift
//  DiscoveryFeature — 공존 카드(라이트, Figma): 소개 + 대표 이미지(+위치 필) + 필요/방해 + 저장.

import SwiftUI
import CorePackage
import DesignTokens

struct CoexistCardView: View {
    let vm: DiscoveryViewModel
    let card: CoexistCard
    let species: Species?
    let candidate: AnalysisCandidate
    @State private var imageURL: URL?

    private var title: String { species?.nameKo ?? candidate.displayName }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: CatureSpacing.md) {
                    header
                    representativeImage
                    infoBlock(title: "이 생명에게 필요한 조건", items: card.needs)
                    infoBlock(title: "사람이 방해할 수 있는 행동", items: card.disturbances)
                }
                .padding(.bottom, CatureSpacing.md)
            }
            saveButton
        }
        .task { imageURL = await fetchRepresentativeImageURL(for: title) }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(title)!")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.black)
            Text(card.intro)
                .font(.system(size: 14))
                .foregroundStyle(.black.opacity(0.5))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 15)
    }

    // 대표 이미지(위키백과) + 위치 필 오버레이
    private var representativeImage: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(CatureColor.surfaceSecondary)
                .frame(height: 245)
                .overlay {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .failure:
                            Image(systemName: "photo").font(.system(size: 40, weight: .thin))
                                .foregroundStyle(.black.opacity(0.25))
                        default:
                            ProgressView().tint(CatureColor.accent)
                        }
                    }
                }
                .clipped()
            if let name = vm.lastLocation?.locationName {
                locationPill(name).padding(.bottom, CatureSpacing.md)
            }
        }
    }

    private func locationPill(_ name: String) -> some View {
        (
            Text("주로 ").foregroundStyle(.black.opacity(0.6))
            + Text(name).fontWeight(.semibold).foregroundStyle(.black)
            + Text(" 지역에서 많이 발견되었어요!").foregroundStyle(.black.opacity(0.6))
        )
        .font(.system(size: 12))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.82), in: Capsule())
        .overlay(Capsule().stroke(.black.opacity(0.05)))
    }

    private func infoBlock(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.black)
            Text(items.joined(separator: "\n"))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.black)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(.black.opacity(0.1)))
        .shadow(color: .black.opacity(0.05), radius: 3)
        .padding(.horizontal, 15)
    }

    private var saveButton: some View {
        Button { Task { await vm.save() } } label: {
            Text("저장하기")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(CatureColor.ink, in: RoundedRectangle(cornerRadius: 15.6, style: .continuous))
        }
        .padding(.horizontal, 23)
        .padding(.vertical, CatureSpacing.sm)
    }
}
