//  CoexistCardView.swift
//  DiscoveryFeature — 발견 정보(Figma 132:715): 위키 이미지 배경(페이드) + 종명 + 위치 + 태그 + 설명 + Needs/Don't + 저장.
//  이미지는 위키백과에서 로드(기존 유지). 좌표는 393×852 프레임 기준.

import SwiftUI
import CorePackage
import DesignTokens

struct CoexistCardView: View {
    let vm: DiscoveryViewModel
    let card: CoexistCard
    let species: Species?
    let candidate: AnalysisCandidate
    let onBack: () -> Void
    @State private var imageURL: URL?

    private var title: String { species?.nameKo ?? candidate.displayName }

    private var tags: [String] {
        var result: [String] = []
        for t in [species?.category, candidate.category] {
            if let t, !t.isEmpty, !result.contains(t) { result.append(t) }
        }
        return result
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(white: 0.949)   // #f2f2f2

            // 위키 이미지 배경 — 상단, 아래로 페이드
            imageBackground

            // 뒤로
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: 40, height: 41, alignment: .leading)
            }
            .accessibilityLabel("뒤로")
            .offset(x: 15, y: 52)

            // 종명 (17, 405)
            Text(title)
                .font(.system(size: 38, weight: .semibold))
                .tracking(-1.9)
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: 360, alignment: .leading)
                .offset(x: 17, y: 402)

            // 위치 (17, 447)
            if let loc = vm.lastLocation?.locationName {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.black.opacity(0.5))
                    Text(loc)
                        .font(.system(size: 13.7))
                        .tracking(-0.55)
                        .foregroundStyle(.black.opacity(0.5))
                }
                .offset(x: 18, y: 445)
            }

            // 태그 (15, 482)
            HStack(spacing: 7) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 13))
                        .tracking(-0.52)
                        .foregroundStyle(.black.opacity(0.7))
                        .padding(.horizontal, 14)
                        .frame(height: 28)
                        .background(Color(white: 0.894), in: Capsule())   // #e4e4e4
                }
            }
            .offset(x: 15, y: 482)

            // 설명 (17, 529)
            Text(card.intro)
                .font(.system(size: 13.1))
                .tracking(-0.52)
                .lineSpacing(6)
                .foregroundStyle(.black.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: 360, alignment: .leading)
                .offset(x: 17, y: 527)

            // Needs / Don't 카드 (16 / 202.5, 611) 176×107
            infoCard(title: "Needs", items: card.needs)
                .offset(x: 16, y: 611)
            infoCard(title: "Don't", items: card.disturbances)
                .offset(x: 201, y: 611)

            // 저장하기 (18, 747) 359×60
            Button { Task { await vm.save() } } label: {
                Text("저장하기")
                    .font(.system(size: 15, weight: .medium))
                    .tracking(-0.6)
                    .foregroundStyle(.white)
                    .frame(width: 359, height: 60)
                    .background(Color(white: 0.157), in: RoundedRectangle(cornerRadius: 15.6, style: .continuous))
            }
            .buttonStyle(.plain)
            .offset(x: 18, y: 747)
        }
        .frame(width: 393, height: 852, alignment: .topLeading)
        .clipped()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(white: 0.949))
        .ignoresSafeArea()
        .task { imageURL = await fetchRepresentativeImageURL(for: title) }
    }

    // 위키 이미지 (상단 ~460, 아래로 페이드아웃)
    private var imageBackground: some View {
        AsyncImage(url: imageURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            default:
                Color(white: 0.9)
            }
        }
        .frame(width: 393, height: 470)
        .clipped()
        .opacity(0.55)
        .mask(
            LinearGradient(
                stops: [.init(color: .black, location: 0),
                        .init(color: .black, location: 0.62),
                        .init(color: .clear, location: 1)],
                startPoint: .top, endPoint: .bottom
            )
        )
        .allowsHitTesting(false)
    }

    // Needs / Don't 정보 카드 (176×107, 흰색, radius 12)
    private func infoCard(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 19, weight: .regular))
                .tracking(-1.34)
                .foregroundStyle(.black.opacity(0.8))
                .padding(.top, 15)
                .padding(.leading, 15)

            Text(items.prefix(2).joined(separator: "\n"))
                .font(.system(size: 13.1, weight: .medium))
                .tracking(-0.65)
                .lineSpacing(3)
                .foregroundStyle(.black.opacity(0.5))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
                .padding(.leading, 16)

            Spacer(minLength: 0)
        }
        .frame(width: 176, height: 107, alignment: .topLeading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.black.opacity(0.05), lineWidth: 1)
        )
    }
}
