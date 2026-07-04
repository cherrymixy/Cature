//  AnalysisView.swift
//  DiscoveryFeature — 분석 결과(후보 + 정보 정확도) + 다시 찍기.

import SwiftUI
import CorePackage
import DesignTokens

struct AnalysisView: View {
    let vm: DiscoveryViewModel
    let candidates: [AnalysisCandidate]

    var body: some View {
        VStack(alignment: .leading, spacing: CatureSpacing.md) {
            Text("이 생물일까요?")
                .font(CatureFont.title)
                .foregroundStyle(CatureColor.darkTextPrimary)
            Text("정보 정확도 순 · 하나를 골라주세요")
                .font(CatureFont.caption)
                .foregroundStyle(CatureColor.darkTextSecondary)

            ForEach(candidates, id: \.self) { candidate in
                Button {
                    Task { await vm.select(candidate) }
                } label: {
                    HStack {
                        Text(candidate.displayName)
                            .font(CatureFont.headline)
                            .foregroundStyle(CatureColor.darkTextPrimary)
                        Spacer()
                        Text("\(Int((candidate.confidence * 100).rounded()))%")
                            .font(CatureFont.body)
                            .foregroundStyle(CatureColor.accent)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .catureCard(.dark)
                }
                .buttonStyle(.plain)
            }

            Spacer()
            Button("인식이 잘못됐나요? 다시 찍기") { vm.retake() }
                .font(CatureFont.callout)
                .foregroundStyle(CatureColor.darkTextSecondary)
                .frame(maxWidth: .infinity)
        }
    }
}
