//  RootView.swift
//  Cature — 홈(지도) (예준 S2 → 승아: MapKit 실지도로 교체).
//
//  실제 MapKit Map: 현재 위치(UserAnnotation) + 발견 기록(SightingRepository) 좌표에 마커.
//  하단 가로 카드 = 발견 생물 · 카테고리 · 현재 위치 기준 실거리.
//  · 좌표 없는 기록은 지도에 안 찍힘(카드에도 제외) — 폴백은 빈 안내.
//  · 하단바/카메라 FAB는 앱 셸(AppShell)이 그리므로 여기선 지도+콘텐츠만.
//  데이터는 CorePackage 프로토콜로만, 스타일은 DesignTokens로만.

import CoreLocation
import CorePackage
import DesignTokens
import MapKit
import SwiftUI

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
    @State private var nearbyCards: [CreatureCardItem] = []
    @State private var discoveredCount = 0

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
        ZStack {
            Map(position: $cameraPosition) {
                UserAnnotation()

                ForEach(markers) { marker in
                    Annotation(marker.name, coordinate: marker.coordinate) {
                        CreatureAnnotationView(name: marker.name)
                    }
                    .annotationTitles(.hidden)
                }
            }
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .ignoresSafeArea()

            // 지도 위 콘텐츠(안전영역 안에서 배치)
            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 0)
                cardRail
            }
        }
        .task { await load() }
    }

    // MARK: 상단 (워드마크 + 발견 수)

    private var topBar: some View {
        HStack(alignment: .center) {
            Text("Cature")
                .font(.system(size: 32, weight: .semibold))
                .kerning(-1.6)
                .foregroundStyle(CatureColor.textPrimary)

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 13, weight: .semibold))
                Text("\(discoveredCount) 발견")
                    .font(CatureFont.caption)
            }
            .foregroundStyle(CatureColor.textPrimary)
            .padding(.horizontal, CatureSpacing.sm)
            .padding(.vertical, CatureSpacing.xs)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(CatureColor.textPrimary.opacity(0.08), lineWidth: 1))
        }
        .padding(.horizontal, CatureSpacing.lg)
        .padding(.top, CatureSpacing.xs)
    }

    // MARK: 하단 근처 카드 레일

    @ViewBuilder
    private var cardRail: some View {
        Group {
            if nearbyCards.isEmpty {
                Text("아직 지도에 표시할 발견이 없어요. 카메라로 첫 발견을 시작해요!")
                    .font(CatureFont.callout)
                    .foregroundStyle(CatureColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, CatureSpacing.md)
                    .padding(.vertical, CatureSpacing.sm)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.horizontal, CatureSpacing.lg)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: CatureSpacing.md) {
                        ForEach(nearbyCards) { item in
                            CreatureMapCard(item: item) { focus(on: item.id) }
                        }
                    }
                    .padding(.horizontal, CatureSpacing.lg)
                }
            }
        }
        .padding(.bottom, 116)   // 셸 플로팅 하단바 위로 띄움
    }

    // MARK: 로드

    @MainActor
    private func load() async {
        async let sightingsResult = sightingRepository.allSightings()
        async let speciesResult = speciesRepository.allSpecies()
        async let entriesResult = collectionRepository.allEntries()
        let currentLocation = await locationService.currentLocation()

        let sightings = (try? await sightingsResult) ?? []
        let species = (try? await speciesResult) ?? []
        let entries = (try? await entriesResult) ?? []

        let speciesById = Dictionary(species.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let discoveredIds = Set(entries.filter(\.discovered).map(\.speciesId))
        discoveredCount = discoveredIds.count

        let userLocation = currentLocation.map {
            CLLocation(latitude: $0.latitude, longitude: $0.longitude)
        }

        var builtMarkers: [CreatureMapMarker] = []
        var builtCards: [CreatureCardItem] = []

        // 최신 발견부터
        for sighting in sightings.sorted(by: { $0.createdAt > $1.createdAt }) {
            guard let latitude = sighting.latitude, let longitude = sighting.longitude else { continue }
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let species = speciesById[sighting.speciesId]
            let name = species?.nameKo ?? sighting.speciesId

            builtMarkers.append(
                CreatureMapMarker(id: sighting.id, name: name, coordinate: coordinate)
            )

            let distanceText: String
            if let userLocation {
                let meters = Int(userLocation.distance(from: CLLocation(latitude: latitude, longitude: longitude)).rounded())
                distanceText = meters > 0 ? Self.formatDistance(meters) : "바로 근처"
            } else {
                distanceText = sighting.locationName ?? "위치 미확인"
            }

            builtCards.append(
                CreatureCardItem(
                    id: sighting.id,
                    name: name,
                    category: species?.category ?? "생물",
                    distanceText: distanceText,
                    discovered: discoveredIds.contains(sighting.speciesId)
                )
            )
        }

        markers = builtMarkers
        nearbyCards = builtCards

        let center = currentLocation.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
            ?? builtMarkers.first?.coordinate
            ?? Self.defaultCenter
        withAnimation {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: center,
                    span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
                )
            )
        }
    }

    private func focus(on markerID: String) {
        guard let marker = markers.first(where: { $0.id == markerID }) else { return }
        withAnimation {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: marker.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
                )
            )
        }
    }

    static let defaultCenter = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780) // 서울시청

    static func formatDistance(_ meters: Int) -> String {
        if meters >= 1000 {
            return String(format: "%.1fkm", Double(meters) / 1000)
        }
        return "\(meters)m"
    }
}

// MARK: - 모델

struct CreatureMapMarker: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
}

struct CreatureCardItem: Identifiable {
    let id: String
    let name: String
    let category: String
    let distanceText: String
    let discovered: Bool
}

// MARK: - 지도 마커 뷰

struct CreatureAnnotationView: View {
    let name: String

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                Circle()
                    .fill(CatureColor.fab)
                    .frame(width: 34, height: 34)
                    .shadow(color: .black.opacity(0.22), radius: 3, y: 1)
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(CatureColor.onFab)
            }

            Text(name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(CatureColor.textPrimary)
                .lineLimit(1)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(CatureColor.surface.opacity(0.92), in: Capsule())
                .overlay(Capsule().stroke(CatureColor.textPrimary.opacity(0.08), lineWidth: 1))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name) 발견 위치")
    }
}

// MARK: - 하단 근처 카드

struct CreatureMapCard: View {
    let item: CreatureCardItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: CatureSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: CatureRadius.md, style: .continuous)
                        .fill(CatureColor.accentSoft)
                        .frame(width: 48, height: 48)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(CatureColor.accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(CatureFont.headline)
                        .foregroundStyle(CatureColor.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text("\(item.category) · \(item.distanceText)")
                        .font(CatureFont.caption)
                        .foregroundStyle(CatureColor.textSecondary)
                        .lineLimit(1)

                    if item.discovered {
                        Text("보유중")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(CatureColor.onFab)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(CatureColor.fab, in: Capsule())
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(CatureSpacing.sm)
            .frame(width: 216, alignment: .leading)
            .background(CatureColor.surface, in: RoundedRectangle(cornerRadius: CatureRadius.card, style: .continuous))
            .shadow(color: CatureColor.textSecondary.opacity(0.12), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.name), \(item.distanceText)")
    }
}

// MARK: - 프리뷰

private enum HomePreviewData {
    static let now = Date(timeIntervalSince1970: 1_720_000_000)

    static var collectionRepository: MockCollectionRepository {
        MockCollectionRepository(entries: [
            CollectionEntry(speciesId: "chameleon", captureCount: 2, discovered: true, firstSeenAt: now, lastSeenAt: now, isFavorite: true),
            CollectionEntry(speciesId: "tree_frog", captureCount: 1, discovered: true, firstSeenAt: now, lastSeenAt: now, isFavorite: false),
        ])
    }

    static var sightingRepository: MockSightingRepository {
        MockSightingRepository(sightings: [
            Sighting(id: "s-chameleon", speciesId: "chameleon", photoPath: "", latitude: 37.5662, longitude: 126.9784, locationName: "서울시청 근처", createdAt: now),
            Sighting(id: "s-frog", speciesId: "tree_frog", photoPath: "", latitude: 37.5679, longitude: 126.9769, locationName: "청계천", createdAt: now.addingTimeInterval(-3600)),
        ])
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
