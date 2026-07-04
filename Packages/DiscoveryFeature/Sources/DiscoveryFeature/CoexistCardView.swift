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

    private var title: String { species?.nameKo ?? candidate.displayName }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CatureSpacing.lg) {
                Text(title)
                    .font(CatureFont.title)
                    .foregroundStyle(CatureColor.darkTextPrimary)

                // usdz 미리보기 자리 (S8 ARFeature에서 실제 로드)
                RoundedRectangle(cornerRadius: CatureRadius.card, style: .continuous)
                    .fill(CatureColor.darkSurfaceElevated)
                    .frame(height: 180)
                    .overlay {
                        VStack(spacing: CatureSpacing.xs) {
                            Image(systemName: "cube.transparent")
                                .font(.system(size: 40, weight: .thin))
                            Text(species?.canExperience == true ? "usdz 미리보기" : "체험 에셋 없음")
                                .font(CatureFont.caption)
                        }
                        .foregroundStyle(CatureColor.darkTextSecondary)
                    }

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
