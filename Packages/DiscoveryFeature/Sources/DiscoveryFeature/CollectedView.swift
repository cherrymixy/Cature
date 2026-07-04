//  CollectedView.swift
//  DiscoveryFeature — 수집 연출(체크 + 발견 + 촬영 N회 + 달성률 + 확인).

import SwiftUI
import DesignTokens

struct CollectedView: View {
    let name: String
    let captureCount: Int
    let achievement: Double
    let canExperience: Bool
    let onExperience: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: CatureSpacing.lg) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(CatureColor.accent)
            Text("\(name) 발견!")
                .font(CatureFont.title)
                .foregroundStyle(CatureColor.darkTextPrimary)
                .multilineTextAlignment(.center)
            Text("촬영 \(captureCount)회")
                .font(CatureFont.body)
                .foregroundStyle(CatureColor.darkTextSecondary)

            VStack(spacing: CatureSpacing.xs) {
                ProgressView(value: achievement).tint(CatureColor.accent)
                Text("도감 달성률 \(Int((achievement * 100).rounded()))%")
                    .font(CatureFont.caption)
                    .foregroundStyle(CatureColor.darkTextSecondary)
            }
            .catureCard(.dark)

            Spacer()
            if canExperience {
                Button("AR로 체험하기") { onExperience() }
                    .buttonStyle(.caturePrimary)
            }
            Button("확인") { onConfirm() }
                .font(CatureFont.headline)
                .foregroundStyle(CatureColor.darkTextPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, CatureSpacing.sm)
        }
    }
}
