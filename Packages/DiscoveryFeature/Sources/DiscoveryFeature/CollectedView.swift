//  CollectedView.swift
//  DiscoveryFeature — 획득 완료(Figma 118:729): 체크 + 종명 + 획득 문구 + 캐릭터(라임 글로우) + 달성률 + [AR 카메라][확인].
//  캐릭터 이미지는 위키백과에서 로드(기존 유지). 좌표는 393×852 프레임 기준.

import SwiftUI
import DesignTokens
#if canImport(UIKit)
import UIKit
#endif

struct CollectedView: View {
    let name: String
    let captureCount: Int
    let achievement: Double
    let canExperience: Bool
    let onExperience: () -> Void
    let onConfirm: () -> Void

    // 종명 → 번들 저폴리 PNG (위키 대신 우리 에셋)
    private var creatureImage: Image? {
        let map = ["꿀벌": "벌"]
        let asset = map[name] ?? name
        #if canImport(UIKit)
        if let ui = UIImage(named: asset, in: .module, with: nil) {
            return Image(uiImage: ui)
        }
        #endif
        return nil
    }

    private var acquiredText: String {
        // 받침 있으면 "을", 없으면 "를"
        let particle = hasFinalConsonant(name) ? "을" : "를"
        return "\(name)\(particle) 획득했어요!"
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(white: 0.949)   // #f2f2f2

            // 체크 뱃지 (158, 36.757, 중앙)
            checkBadge
                .frame(width: 393, alignment: .center)
                .offset(y: 158)

            // 종명 (215, 중앙)
            Text(name)
                .font(.system(size: 38, weight: .semibold))
                .tracking(-1.9)
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: 393, alignment: .center)
                .offset(y: 209)

            // 획득 문구 (257, 중앙)
            Text(acquiredText)
                .font(.system(size: 14, weight: .medium))
                .tracking(-0.42)
                .foregroundStyle(.black.opacity(0.5))
                .frame(width: 393, alignment: .center)
                .offset(y: 257)

            // 캐릭터 + 라임 글로우 (중앙, y≈342)
            creatureBody
                .frame(width: 393, alignment: .center)
                .offset(y: 320)

            // 달성률 (626, 중앙)
            Text("달성률 \(String(format: "%.1f", achievement * 100))%")
                .font(.system(size: 13, weight: .semibold))
                .tracking(-0.39)
                .foregroundStyle(.black.opacity(0.6))
                .frame(width: 94, height: 32)
                .background(.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 5.66, style: .continuous))
                .frame(width: 393, alignment: .center)
                .offset(y: 626)

            // 버튼 (747)
            buttons
        }
        .frame(width: 393, height: 852, alignment: .topLeading)
        .clipped()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(white: 0.949))
        .ignoresSafeArea()
    }

    private var checkBadge: some View {
        ZStack {
            Circle().fill(.black)
            Image(systemName: "checkmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(CatureColor.lime)
        }
        .frame(width: 36.757, height: 36.757)
    }

    // 번들 저폴리 PNG + 라임 글로우
    private var creatureBody: some View {
        ZStack {
            Circle()
                .fill(CatureColor.lime.opacity(0.5))
                .frame(width: 250, height: 250)
                .blur(radius: 50)
            Group {
                if let creatureImage {
                    creatureImage.resizable().scaledToFit()
                } else {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(.black.opacity(0.3))
                }
            }
            .frame(width: 209, height: 217)
        }
        .frame(width: 269, height: 270)
    }

    @ViewBuilder
    private var buttons: some View {
        if canExperience {
            Button(action: onExperience) { darkButton("AR 카메라", width: 174) }
                .buttonStyle(.plain)
                .offset(x: 18, y: 747)
            Button(action: onConfirm) { darkButton("확인", width: 174) }
                .buttonStyle(.plain)
                .offset(x: 201, y: 747)
        } else {
            Button(action: onConfirm) { darkButton("확인", width: 357) }
                .buttonStyle(.plain)
                .offset(x: 18, y: 747)
        }
    }

    private func darkButton(_ title: String, width: CGFloat) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .medium))
            .tracking(-0.6)
            .foregroundStyle(.white)
            .frame(width: width, height: 60.629)
            .background(Color(white: 0.157), in: RoundedRectangle(cornerRadius: 15.6, style: .continuous))
    }
}

// 한글 받침 판별 (조사 을/를)
private func hasFinalConsonant(_ text: String) -> Bool {
    guard let last = text.unicodeScalars.last?.value else { return false }
    guard last >= 0xAC00, last <= 0xD7A3 else { return false }
    return (last - 0xAC00) % 28 != 0
}
