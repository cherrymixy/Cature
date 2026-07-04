//  RootView.swift
//  Cature — 홈(지도). 예준 S2 Figma(fnzi6v9) 디자인 + 승아: 실제 MapKit 모노톤 지도.
//
//  · 베이스: 풀스크린 SwiftUI Map(.grayscale 모노톤) + 현재 위치 + Sighting 좌표 마커.
//  · 크롬(Figma): Josefin 워드마크 "Cature" / 라임 Nearby 필터칩 레일 / 이미지 마커+라벨칩 / 라임 active 동물카드.
//  · 하단 내비/캡처 FAB는 앱 셸(AppShell) 몫 — 여기선 안 그림.
//  데이터는 CorePackage 프로토콜로만, 색·폰트는 DesignTokens로만.

import CoreLocation
import CorePackage
import DesignTokens
import MapKit
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

public struct RootView: View {
    private let collectionRepository: any CollectionRepository
    private let sightingRepository: any SightingRepository
    private let speciesRepository: any SpeciesRepository
    private let locationService: any LocationService

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: RootView.defaultCenter,
            span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
        )
    )
    @State private var markers: [CreatureMapMarker] = []
    @State private var cards: [CreatureCardItem] = []
    @State private var discoveredCount = 0
    @State private var selectedCardID: String?
    @State private var mapCameraTick = 0   // 카메라 변할 때 컬러 마커 오버레이 재배치 트리거

    public init(
        collectionRepository: any CollectionRepository = MockCollectionRepository(),
        sightingRepository: any SightingRepository = MockSightingRepository(),
        speciesRepository: any SpeciesRepository = MockSpeciesRepository(),
        locationService: any LocationService = MockLocationService()
    ) {
        self.collectionRepository = collectionRepository
        self.sightingRepository = sightingRepository
        self.speciesRepository = speciesRepository
        self.locationService = locationService
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            MapReader { proxy in
                Map(position: $cameraPosition) {
                    UserAnnotation()
                }
                .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
                .grayscale(1.0)   // 지도 레이어만 모노톤
                .overlay {
                    // 컬러 마커 — grayscale 밖 오버레이에 좌표변환으로 배치(지도는 흑백, 마커만 컬러)
                    let _ = mapCameraTick   // 카메라 변경 시 재계산 트리거
                    ForEach(markers) { marker in
                        if let point = proxy.convert(marker.coordinate, to: .local) {
                            CreatureMarkerView(name: marker.name, speciesId: marker.speciesId)
                                .position(point)
                        }
                    }
                }
                .onMapCameraChange(frequency: .continuous) { _ in
                    mapCameraTick &+= 1
                }
                .ignoresSafeArea()
            }

            VStack(alignment: .leading, spacing: 0) {
                titleBar
                filterRail
                    .padding(.top, CatureSpacing.sm)
                Spacer(minLength: 0)
                cardRail
            }
        }
        .task { await load() }
    }

    // MARK: 타이틀 (Cature 워드마크 로고 — Assets3D/Cature.svg)

    private var titleBar: some View {
        Image("cature-logo", bundle: .module)
            .resizable()
            .scaledToFit()
            .frame(height: 34)
            .padding(.leading, CatureSpacing.md)
            .padding(.top, CatureSpacing.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: 필터 칩 레일 (Figma: + / Nearby(라임) / Home·Office·Addxd)

    private var filterRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                CircleButton(systemName: "plus")
                FilterChip(title: "Nearby", systemName: "mappin.and.ellipse", count: nil, isSelected: true)
                FilterChip(title: "Home", systemName: nil, count: max(discoveredCount, 3), isSelected: false)
                FilterChip(title: "Office", systemName: nil, count: 6, isSelected: false)
                FilterChip(title: "Addxd", systemName: nil, count: 1, isSelected: false)
            }
            .padding(.horizontal, CatureSpacing.md)
        }
    }

    // MARK: 하단 동물 카드 레일

    @ViewBuilder
    private var cardRail: some View {
        Group {
            if cards.isEmpty {
                Text("아직 지도에 표시할 발견이 없어요. 카메라로 첫 발견을 시작해요!")
                    .font(CatureFont.callout)
                    .foregroundStyle(CatureColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, CatureSpacing.md)
                    .padding(.vertical, CatureSpacing.sm)
                    .background(.ultraThinMaterial, in: Capsule())
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, CatureSpacing.lg)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 11) {
                        ForEach(cards) { item in
                            Button {
                                select(item)
                            } label: {
                                AnimalCard(item: item, isActive: item.id == selectedCardID)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, CatureSpacing.md)
                }
            }
        }
        .padding(.bottom, 86)   // GNB 위 20px (요청: 10px 더 내림)
    }

    // MARK: 로드

    @MainActor
    private func load() async {
        // 발견/종/수집은 로컬 읽기 — 위치 없이 먼저 핀·카드를 그린다(위치 권한 대기에 막히지 않게).
        async let sightingsResult = sightingRepository.allSightings()
        async let speciesResult = speciesRepository.allSpecies()
        async let entriesResult = collectionRepository.allEntries()

        let sightings = (try? await sightingsResult) ?? []
        let species = (try? await speciesResult) ?? []
        let entries = (try? await entriesResult) ?? []

        let speciesById = Dictionary(species.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let discoveredIds = Set(entries.filter(\.discovered).map(\.speciesId))
        discoveredCount = discoveredIds.count

        var builtMarkers: [CreatureMapMarker] = []
        var builtCards: [CreatureCardItem] = []
        for sighting in sightings.sorted(by: { $0.createdAt > $1.createdAt }) {
            guard let latitude = sighting.latitude, let longitude = sighting.longitude else { continue }
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let korean = speciesById[sighting.speciesId]?.nameKo ?? sighting.speciesId
            builtMarkers.append(
                CreatureMapMarker(id: sighting.id, name: korean, speciesId: sighting.speciesId, coordinate: coordinate)
            )
            builtCards.append(
                CreatureCardItem(
                    id: sighting.id,
                    speciesId: sighting.speciesId,
                    english: Self.englishName(sighting.speciesId),
                    korean: korean,
                    distanceText: sighting.locationName ?? "근처",
                    discovered: discoveredIds.contains(sighting.speciesId)
                )
            )
        }

        markers = builtMarkers
        cards = builtCards
        selectedCardID = builtCards.first?.id
        if !builtMarkers.isEmpty {
            // 핀들의 무게중심에 맞춰 3개가 화면 중앙에 모이게(상단 타이틀/하단 카드 안 가리게).
            let lat = builtMarkers.map(\.coordinate.latitude).reduce(0, +) / Double(builtMarkers.count)
            let lon = builtMarkers.map(\.coordinate.longitude).reduce(0, +) / Double(builtMarkers.count)
            withAnimation {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                        span: MKCoordinateSpan(latitudeDelta: 0.011, longitudeDelta: 0.011)
                    )
                )
            }
        }

        // 위치는 이후에(권한 대기 가능) — 카드 거리만 실측으로 갱신. 지도 중심은 핀 유지.
        guard let sample = await locationService.currentLocation() else { return }
        let user = CLLocation(latitude: sample.latitude, longitude: sample.longitude)
        let coordByID = Dictionary(uniqueKeysWithValues: builtMarkers.map { ($0.id, $0.coordinate) })
        cards = builtCards.map { card in
            guard let coord = coordByID[card.id] else { return card }
            let meters = Int(user.distance(from: CLLocation(latitude: coord.latitude, longitude: coord.longitude)).rounded())
            return CreatureCardItem(
                id: card.id, speciesId: card.speciesId, english: card.english, korean: card.korean,
                distanceText: meters > 0 ? Self.formatDistance(meters) : "바로 근처",
                discovered: card.discovered
            )
        }
    }

    private func select(_ item: CreatureCardItem) {
        selectedCardID = item.id
        guard let marker = markers.first(where: { $0.id == item.id }) else { return }
        withAnimation {
            cameraPosition = .region(
                MKCoordinateRegion(center: marker.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006))
            )
        }
    }

    static let defaultCenter = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780) // 서울시청

    static func formatDistance(_ meters: Int) -> String {
        meters >= 1000 ? String(format: "%.1fkm", Double(meters) / 1000) : "\(meters)m"
    }

    /// species id → 영문 카드 타이틀 (예: "tree_frog" → "Tree Frog").
    static func englishName(_ id: String) -> String {
        id.split(separator: "_").map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
    }
}

// MARK: - 모델

struct CreatureMapMarker: Identifiable {
    let id: String            // sighting id
    let name: String          // 한글명
    let speciesId: String
    let coordinate: CLLocationCoordinate2D
}

struct CreatureCardItem: Identifiable {
    let id: String            // sighting id
    let speciesId: String
    let english: String
    let korean: String
    let distanceText: String
    let discovered: Bool
}

// MARK: - 번들 이미지 존재 확인 (loose PNG, iOS만)

enum HomeAssets {
    /// 마커 원 안에 넣을 생물 이미지 (카드플립 GameAssets에서 가져온 creature-<id>).
    static func creatureImageName(_ speciesId: String) -> String? {
        exists("creature-\(speciesId)") ? "creature-\(speciesId)" : nil
    }

    /// 카드 이미지 — 전용 card-<id> 우선, 없으면 creature-<id>.
    static func cardImageName(_ speciesId: String) -> String? {
        if exists("card-\(speciesId)") { return "card-\(speciesId)" }
        if exists("creature-\(speciesId)") { return "creature-\(speciesId)" }
        return nil
    }

    #if canImport(UIKit)
    private static func exists(_ name: String) -> Bool { UIImage(named: name, in: .module, with: nil) != nil }
    #else
    private static func exists(_ name: String) -> Bool { false }
    #endif
}

/// SPM 리소스의 loose PNG는 SwiftUI `Image(name:bundle:)`로 렌더가 안 될 때가 있어 UIImage 경유로 로드.
struct BundledImage: View {
    let name: String

    var body: some View {
        #if canImport(UIKit)
        if let ui = UIImage(named: name, in: .module, with: nil) {
            Image(uiImage: ui).resizable()
        } else {
            Color.clear
        }
        #else
        Image(name, bundle: .module).resizable()
        #endif
    }
}

// MARK: - 지도 마커 (Figma: 이미지 마커 + 라벨 칩)

struct CreatureMarkerView: View {
    let name: String
    let speciesId: String

    var body: some View {
        VStack(spacing: -4) {
            ZStack {
                Circle()
                    .fill(CatureColor.surface)
                    .frame(width: 54, height: 54)
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 0.5)
                creatureImage
                Circle()
                    .stroke(CatureColor.lime, lineWidth: 3)
                    .frame(width: 54, height: 54)
            }

            // 라벨 칩 + 아래 삼각형 — 둘 다 ink로 1px 겹쳐 흰 선(seam) 없이 이어붙임
            VStack(spacing: -1) {
                Text(name)
                    .font(.system(size: 12.3, weight: .semibold))
                    .foregroundStyle(CatureColor.onFab)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(CatureColor.ink, in: Capsule())
                DownTriangle()
                    .fill(CatureColor.ink)
                    .frame(width: 12, height: 6)
            }
        }
        .frame(width: 88)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name) 발견 위치")
    }

    // 원 안 = 생물 이미지(있으면), 없으면 이름 첫 글자 (발바닥 대체)
    @ViewBuilder
    private var creatureImage: some View {
        if let asset = HomeAssets.creatureImageName(speciesId) {
            BundledImage(name: asset)
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
        } else {
            Text(String(name.prefix(1)))
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(CatureColor.textPrimary)
                .frame(width: 50, height: 50)
        }
    }
}

/// 라벨 칩 아래 붙는 하향 삼각형 포인터.
struct DownTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - 필터 칩 (Figma: Nearby=라임, 나머지=흰 + 카운트)

struct CircleButton: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 18, weight: .regular))
            .foregroundStyle(CatureColor.textPrimary)
            .frame(width: 38, height: 38)
            .background(CatureColor.surface)
            .clipShape(Circle())
            .overlay(Circle().stroke(CatureColor.textPrimary.opacity(0.08), lineWidth: 1))
    }
}

struct FilterChip: View {
    let title: String
    let systemName: String?
    let count: Int?
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 5) {
            if let systemName {
                Image(systemName: systemName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.black)
            }
            if let count {
                Text("\(count)")
                    .font(.system(size: 13.5, weight: .regular))
                    .foregroundStyle(CatureColor.textPrimary.opacity(0.7))
                    .frame(width: 19, height: 19)
                    .background(CatureColor.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 9.5, style: .continuous))
            }
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isSelected ? .black : CatureColor.textPrimary.opacity(0.7))
                .lineLimit(1)
        }
        .padding(.horizontal, isSelected ? 18 : 10)
        .frame(height: 38)
        .background(isSelected ? CatureColor.lime : CatureColor.surface)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(CatureColor.textPrimary.opacity(isSelected ? 0 : 0.1), lineWidth: 1))
    }
}

// MARK: - 동물 카드 (Figma: active=라임, Josefin 타이틀, 보유중, 거리)

struct AnimalCard: View {
    let item: CreatureCardItem
    let isActive: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            VStack(alignment: .leading, spacing: 15) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.english)
                        .font(CatureFont.wordmark(size: 28))
                        .foregroundStyle(CatureColor.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(item.korean)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(CatureColor.textPrimary.opacity(0.5))
                }

                VStack(alignment: .leading, spacing: 3) {
                    if item.discovered {
                        Text("보유중")
                            .font(.system(size: 11.3, weight: .medium))
                            .foregroundStyle(CatureColor.onFab)
                            .frame(width: 48, height: 18)
                            .background(CatureColor.ink)
                            .clipShape(Capsule())
                    }
                    Text("\(item.distanceText) · 발견 확률 높음")
                        .font(.system(size: 12.7, weight: .medium))
                        .foregroundStyle(CatureColor.textPrimary.opacity(0.5))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .frame(width: 131, alignment: .leading)

            Spacer(minLength: 0)

            if let asset = HomeAssets.cardImageName(item.speciesId) {
                BundledImage(name: asset)
                    .scaledToFill()
                    .frame(width: 101, height: 104)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .padding(.top, 16)
        .padding(.leading, 16)
        .padding(.trailing, 18)
        .padding(.bottom, 13)
        .frame(width: 282, height: 133)
        .background(isActive ? CatureColor.lime : CatureColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: CatureColor.textSecondary.opacity(isActive ? 0.05 : 0.04), radius: isActive ? 6 : 2)
    }
}

// MARK: - 프리뷰

private enum HomePreviewData {
    static let now = Date(timeIntervalSince1970: 1_720_000_000)

    // 앱 데모와 동일한 3종(고양이/닭/느티나무)
    static var collectionRepository: MockCollectionRepository {
        MockCollectionRepository(entries: SampleData.demoSightings.map {
            CollectionEntry(speciesId: $0.speciesId, captureCount: 1, discovered: true, firstSeenAt: now, lastSeenAt: now, isFavorite: false)
        })
    }

    static var sightingRepository: MockSightingRepository {
        MockSightingRepository(sightings: SampleData.demoSightings)
    }
}

#Preview("홈 지도") {
    RootView(
        collectionRepository: HomePreviewData.collectionRepository,
        sightingRepository: HomePreviewData.sightingRepository,
        speciesRepository: MockSpeciesRepository(),
        locationService: MockLocationService(
            sample: LocationSample(latitude: 37.5665, longitude: 126.9780, locationName: "서울특별시 중구")
        )
    )
}

#Preview("빈 상태") {
    RootView(
        collectionRepository: MockCollectionRepository(),
        sightingRepository: MockSightingRepository(),
        speciesRepository: MockSpeciesRepository(),
        locationService: MockLocationService(sample: nil)
    )
}
