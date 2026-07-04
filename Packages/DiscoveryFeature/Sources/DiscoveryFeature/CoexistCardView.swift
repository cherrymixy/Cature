//  CoexistCardView.swift
//  DiscoveryFeature — 공존 카드(소개 + usdz 미리보기 자리 + 필요/방해 + 저장).

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
        ScrollView {
            VStack(alignment: .leading, spacing: CatureSpacing.lg) {
                Text(title)
                    .font(CatureFont.title)
                    .foregroundStyle(CatureColor.darkTextPrimary)

                // 대표 이미지 (위키백과, 종 이름으로 조회)
                RoundedRectangle(cornerRadius: CatureRadius.card, style: .continuous)
                    .fill(CatureColor.darkSurfaceElevated)
                    .frame(height: 200)
                    .overlay {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            case .failure:
                                imagePlaceholder
                            default:
                                ProgressView().tint(CatureColor.accent)
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: CatureRadius.card, style: .continuous))
                    .task { imageURL = await fetchRepresentativeImageURL(for: title) }

                Text(card.intro)
                    .font(CatureFont.body)
                    .foregroundStyle(CatureColor.darkTextPrimary)

                block(title: "필요한 것", items: card.needs)
                block(title: "방해되는 것", items: card.disturbances)

                Button("저장하기") { Task { await vm.save() } }
                    .buttonStyle(.caturePrimary)
                    .padding(.top, CatureSpacing.sm)
            }
        }
    }

    private var imagePlaceholder: some View {
        VStack(spacing: CatureSpacing.xs) {
            Image(systemName: "photo").font(.system(size: 40, weight: .thin))
            Text("대표 이미지 없음").font(CatureFont.caption)
        }
        .foregroundStyle(CatureColor.darkTextSecondary)
    }

    private func block(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: CatureSpacing.xs) {
            Text(title)
                .font(CatureFont.caption)
                .foregroundStyle(CatureColor.accent)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: CatureSpacing.xs) {
                    Text("•").foregroundStyle(CatureColor.darkTextSecondary)
                    Text(item)
                        .font(CatureFont.body)
                        .foregroundStyle(CatureColor.darkTextPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .catureCard(.dark)
    }
}
