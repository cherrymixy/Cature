//  AnalysisView.swift
//  DiscoveryFeature — 분석(라이트, Figma): 찍은 사진 + 후보(카테고리·이름·정확도) 2단계 선택 + 선택하기.

import SwiftUI
import CorePackage
import DesignTokens
#if canImport(UIKit)
import UIKit
#endif

struct AnalysisView: View {
    let vm: DiscoveryViewModel
    let candidates: [AnalysisCandidate]
    @State private var selected: AnalysisCandidate?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: CatureSpacing.md) {
                    header
                    capturedImage
                    ForEach(candidates, id: \.self) { candidateCard($0) }
                }
                .padding(.horizontal, 15)
                .padding(.top, 40)   // 뒤로 버튼과 여백 확보
                .padding(.bottom, CatureSpacing.md)
            }
            selectButton
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("이 친구는 누구일까요?")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.black)
            Text("사진 속 생물을 AI가 분석했어요")
                .font(.system(size: 14))
                .foregroundStyle(.black.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // 방금 찍은 사진
    @ViewBuilder private var capturedImage: some View {
        if let url = vm.lastPhoto, let image = Self.loadImage(url) {
            image
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // 후보 카드: 탭 → 하이라이트(라임), '선택하기'로 확정.
    private func candidateCard(_ candidate: AnalysisCandidate) -> some View {
        let isSelected = selected == candidate
        let isTop = candidate == candidates.first
        // % 필: top 후보는 기본 검정 배경+포인트 텍스트, 선택 시 포인트 배경. 나머지는 선택 시 검정+포인트.
        let pillOnPoint = isTop && isSelected
        let pillDark = (isTop && !isSelected) || (!isTop && isSelected)
        let pillBG = pillOnPoint ? CatureColor.accent : (pillDark ? Color.black : Color(red: 0.89, green: 0.89, blue: 0.89))
        let pillFG = pillOnPoint ? Color.black : (pillDark ? CatureColor.accent : Color(red: 0.72, green: 0.72, blue: 0.72))
        return Button { selected = candidate } label: {
            HStack(spacing: CatureSpacing.sm) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(candidate.category ?? "생물")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.black.opacity(0.4))
                    Text(candidate.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                }
                Spacer()
                Text("\(Int((candidate.confidence * 100).rounded()))%")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(pillFG)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 2)
                    .background(pillBG, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(isSelected ? CatureColor.lime : Color.white,
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(.black.opacity(0.1)))
            .shadow(color: .black.opacity(0.05), radius: 3)
        }
        .buttonStyle(.plain)
    }

    private var selectButton: some View {
        Button {
            if let selected { Task { await vm.select(selected) } }
        } label: {
            Text("선택하기")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    selected == nil ? CatureColor.ink.opacity(0.35) : CatureColor.ink,
                    in: RoundedRectangle(cornerRadius: 15.6, style: .continuous)
                )
        }
        .disabled(selected == nil)
        .padding(.horizontal, 23)
        .padding(.vertical, CatureSpacing.sm)
    }

    private static func loadImage(_ url: URL) -> Image? {
        #if canImport(UIKit)
        if let ui = UIImage(contentsOfFile: url.path) { return Image(uiImage: ui) }
        #endif
        return nil
    }
}
