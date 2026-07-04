//  Previews.swift
//  DesignTokens — 토큰 적용 확인용 샘플 프리뷰 (S2 점검).

import SwiftUI

#Preview("Cature 디자인 토큰") {
    ScrollView {
        VStack(alignment: .leading, spacing: CatureSpacing.lg) {

            Text("TYPOGRAPHY")
                .font(CatureFont.caption)
                .foregroundStyle(CatureColor.textSecondary)
            VStack(alignment: .leading, spacing: CatureSpacing.xs) {
                Text("Large Title").font(CatureFont.largeTitle)
                Text("Title").font(CatureFont.title)
                Text("Headline").font(CatureFont.headline)
                Text("Body — 이해·배려의 톤으로.").font(CatureFont.body)
                Text("Caption").font(CatureFont.caption)
            }
            .foregroundStyle(CatureColor.textPrimary)

            Text("CARD (light)")
                .font(CatureFont.caption)
                .foregroundStyle(CatureColor.textSecondary)
            VStack(alignment: .leading, spacing: CatureSpacing.xs) {
                Text("카멜레온").font(CatureFont.headline).foregroundStyle(CatureColor.textPrimary)
                Text("느리게 움직이며 주변에 몸 색을 맞춰요.")
                    .font(CatureFont.body).foregroundStyle(CatureColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .catureCard(.light)

            Button("저장하기") {}
                .buttonStyle(.caturePrimary)

            HStack(spacing: CatureSpacing.sm) {
                ForEach(["홈", "기능", "마이"], id: \.self) { label in
                    Text(label).font(CatureFont.callout).foregroundStyle(CatureColor.textPrimary)
                }
            }
            .caturePillTab(.light)
        }
        .padding(CatureSpacing.lg)
    }
    .background(CatureColor.surfaceSecondary)
}
