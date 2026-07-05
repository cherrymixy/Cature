//  MyCollectionView.swift
//  DexFeature — 도감(마이페이지). Figma/HTML 목업 그대로: 프로필 + 탭 + 필터 + 3열 카드 그리드.
//  ⚠️ 목업 정적 데이터(승아 구현, DexFeature 소유=찬희 조율 필요).

import SwiftUI
import DesignTokens

private struct DexCard: Identifiable {
    let id = UUID()
    let name: String
    let image: String
    let blob: String?      // nil이면 round-bg 스타일
    let round: Bool
    let cat: String        // "animal" / "plant" / "insect"
    let w: CGFloat, h: CGFloat, x: CGFloat, y: CGFloat
}

struct MyCollectionView: View {
    @State private var filterIndex = 0
    @State private var showComingSoon = false

    private let filters = ["ALL", "Animal", "Plant", "Incect"]
    private let columns = Array(repeating: GridItem(.fixed(112), spacing: 13), count: 3)

    // HTML 목업 카드 순서/치수 그대로
    private let cards: [DexCard] = [
        .init(name: "드라세나", image: "plant",     blob: "card-blob-f", round: false, cat: "plant",  w: 69, h: 82, x: 21, y: 13),
        .init(name: "닭",       image: "chicken",   blob: "card-blob-d", round: false, cat: "animal", w: 75, h: 83, x: 17, y: 16),
        .init(name: "파리",     image: "fly",       blob: "card-blob-b", round: false, cat: "insect", w: 88, h: 71, x: 11, y: 24),
        .init(name: "느티나무", image: "tree-bg",   blob: "card-blob-a", round: true,  cat: "plant",  w: 88, h: 88, x: 12, y: 16),
        .init(name: "개미",     image: "ant",       blob: "card-blob-a", round: false, cat: "insect", w: 96, h: 90, x: 5,  y: 14),
        .init(name: "카멜레온", image: "chameleon", blob: "card-blob-c", round: false, cat: "insect", w: 77, h: 80, x: 17, y: 11),
        .init(name: "청둥오리", image: "duck-bg",   blob: "card-blob-a", round: true,  cat: "animal", w: 88, h: 88, x: 12, y: 16),
        .init(name: "선인장",   image: "cactus",    blob: "card-blob-e", round: false, cat: "plant",  w: 67, h: 73, x: 25, y: 23),
        .init(name: "무당벌레", image: "ladybug",   blob: "card-blob-a", round: false, cat: "insect", w: 87, h: 79, x: 12, y: 19),
        .init(name: "야생버섯", image: "mushroom",  blob: "card-blob-e", round: false, cat: "plant",  w: 84, h: 68, x: 14, y: 23),
        .init(name: "뚱냥이",   image: "cat",       blob: "card-blob-c", round: false, cat: "animal", w: 89, h: 76, x: 7,  y: 16),
        .init(name: "꿀벌",     image: "bee",       blob: "card-blob-a", round: false, cat: "insect", w: 98, h: 87, x: 6,  y: 12),
    ]

    private var filteredCards: [DexCard] {
        switch filterIndex {
        case 1:  return cards.filter { $0.cat == "animal" }
        case 2:  return cards.filter { $0.cat == "plant" }
        case 3:  return cards.filter { $0.cat == "insect" }
        default: return cards
        }
    }

    // 색 (목업 hex)
    private let bgGray = Color(red: 0.949, green: 0.949, blue: 0.949)   // #f2f2f2
    private let cardGray = Color(red: 0.914, green: 0.914, blue: 0.914) // #e9e9e9

    var body: some View {
        ZStack(alignment: .topLeading) {
            bgGray.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                topBar
                profile
                tabs
                panel
            }
        }
        .alert("준비 중입니다", isPresented: $showComingSoon) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("미션 기능은 곧 만나볼 수 있어요.")
        }
    }

    private var topBar: some View {
        HStack(alignment: .center) {
            Image("my-logo", bundle: .module)
                .resizable()
                .scaledToFit()
                .frame(height: 32)
                .accessibilityLabel("My")
            Spacer()
            VStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule().fill(.black.opacity(0.55)).frame(width: 23, height: 2.4)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
    }

    private var profile: some View {
        HStack(spacing: 18) {
            Image("avatar", bundle: .module)
                .resizable().scaledToFill()
                .frame(width: 65, height: 65)
                .background(Color(red: 0.329, green: 0.757, blue: 0.788))   // #54c1c9
                .clipShape(Circle())
                .overlay(Circle().stroke(Color(white: 0.88)))
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 9) {
                    Text("오민주").font(.system(size: 24, weight: .bold)).tracking(-0.96)
                    Text("LV.2")
                        .font(.system(size: 11, weight: .medium)).tracking(-0.44)
                        .foregroundStyle(Color(red: 0.337, green: 0.337, blue: 0.337))
                        .frame(width: 36, height: 18)
                        .background(Color(red: 0.914, green: 0.914, blue: 0.914), in: Capsule())
                }
                Text("비범탄탄민주").font(.system(size: 14)).foregroundStyle(.black.opacity(0.5))
            }
            Spacer()
        }
        .padding(.leading, 16)
        .padding(.top, 24)
    }

    private var tabs: some View {
        HStack(spacing: 0) {
            tabButton("Collection", active: true) {}
            tabButton("Misson", active: false) { showComingSoon = true }
            Spacer()
        }
        .padding(.top, 30)
    }

    private func tabButton(_ title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium)).tracking(-0.56)
                .foregroundStyle(active ? .black : .black.opacity(0.22))
                .frame(width: 111, height: 33)
                .background(
                    active ? Color.white : Color(red: 0.91, green: 0.91, blue: 0.91),
                    in: UnevenRoundedRectangle(topLeadingRadius: 23, topTrailingRadius: 23)
                )
        }
        .buttonStyle(.plain)
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 5) {
                ForEach(filters.indices, id: \.self) { filterChip($0) }
            }
            .padding(.leading, 16)
            .padding(.trailing, 12)
            .padding(.top, 18)
            .padding(.bottom, 16)   // 태그 아래 여백 (스크롤 내려도 카드가 태그에 안 닿게)

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                    ForEach(filteredCards) { cardView($0) }
                }
                .padding(.leading, 16)
                .padding(.top, 4)
                .padding(.bottom, 130)   // 셸 하단 nav 공간
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white)
    }

    private func filterChip(_ i: Int) -> some View {
        let active = filterIndex == i
        return Button { filterIndex = i } label: {
            Text(filters[i])
                .font(.system(size: 16, weight: active ? .bold : .semibold)).tracking(-0.48)
                .foregroundStyle(active ? .black : .black.opacity(0.7))
                .frame(height: 38)
                .padding(.horizontal, 16)
                .background(active ? CatureColor.accent : Color.white, in: Capsule())
                .overlay(Capsule().stroke(active ? Color.clear : .black.opacity(0.1)))
        }
        .buttonStyle(.plain)
    }

    private func cardView(_ c: DexCard) -> some View {
        ZStack(alignment: .topLeading) {
            // 카드 = 그레이. 블롭 모양만 흰 베이스가 비치도록 구멍을 뚫는다.
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white)
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(cardGray)
                    .overlay {
                        if let blob = c.blob {
                            Image(blob, bundle: .module)
                                .renderingMode(.template)
                                .resizable()
                                .foregroundStyle(.black)
                                .frame(width: 112, height: 146)
                                .blendMode(.destinationOut)   // 블롭 부분을 파내 흰 베이스가 보이게
                        }
                    }
                    .compositingGroup()
            }
            .frame(width: 112, height: 146)

            if c.round {
                Image(c.image, bundle: .module)
                    .resizable().scaledToFill()
                    .frame(width: c.w, height: c.h)
                    .clipShape(Circle())
                    .offset(x: c.x, y: c.y)
            } else {
                Image(c.image, bundle: .module)
                    .resizable().scaledToFit()
                    .frame(width: c.w, height: c.h)
                    .offset(x: c.x, y: c.y)
            }

            Text(c.name)
                .font(.system(size: 16, weight: .heavy)).tracking(-0.64)
                .foregroundStyle(.black)
                .frame(width: 112)
                .offset(y: 104)

            Text("26.10.12")
                .font(.system(size: 10, weight: .medium)).tracking(-0.4)
                .foregroundStyle(.black.opacity(0.3))
                .frame(width: 112)
                .offset(y: 125)
        }
        .frame(width: 112, height: 146)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
