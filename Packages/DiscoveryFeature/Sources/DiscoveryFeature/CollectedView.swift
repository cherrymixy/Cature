//  CollectedView.swift
//  DiscoveryFeature — 수집 연출(라이트, Figma): 체크 + 획득 + 촬영 N회 + 모델(라임 글로우) + 달성률 + 버튼.

import SwiftUI
import DesignTokens

struct CollectedView: View {
    let name: String
    let captureCount: Int
    let achievement: Double
    let canExperience: Bool
    let onExperience: () -> Void
    let onConfirm: () -> Void
    @State private var imageURL: URL?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            checkMark
            Text("\(name)을 획득했어요!")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
                .padding(.top, CatureSpacing.md)
            Text("\(name) 촬영 \(captureCount)회")
                .font(.system(size: 15))
                .foregroundStyle(.black.opacity(0.8))
                .padding(.top, 4)
            modelImage
                .padding(.vertical, CatureSpacing.md)
            achievementPill
            Spacer()
            buttons
                .padding(.horizontal, 17)
                .padding(.bottom, CatureSpacing.lg)
        }
        .task { imageURL = await fetchRepresentativeImageURL(for: name) }
    }

    private var checkMark: some View {
        ZStack {
            Circle().fill(CatureColor.ink).frame(width: 40, height: 40)
            Image(systemName: "checkmark")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(CatureColor.lime)
        }
    }

    // 대표 이미지(위키백과) + 라임 글로우 후광
    private var modelImage: some View {
        ZStack {
            Circle()
                .fill(CatureColor.lime.opacity(0.55))
                .frame(width: 230, height: 230)
                .blur(radius: 45)
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit()
                default:
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(.black.opacity(0.3))
                }
            }
            .frame(width: 220, height: 200)
        }
    }

    private var achievementPill: some View {
        Text("달성률 \(String(format: "%.1f", achievement * 100))%")
            .font(.system(size: 12.5, weight: .semibold))
            .foregroundStyle(.black.opacity(0.6))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private var buttons: some View {
        HStack(spacing: CatureSpacing.sm) {
            if canExperience {
                darkButton("AR 체험하러 가기", action: onExperience)
            }
            darkButton("확인", action: onConfirm)
        }
    }

    private func darkButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(CatureColor.ink, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
