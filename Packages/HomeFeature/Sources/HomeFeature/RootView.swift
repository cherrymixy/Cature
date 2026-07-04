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

    @State private var creatures: [HomeCreature] = []
    @State private var selectedCreatureId: String?
    @State private var cameraPosition: MapCameraPosition = .region(Self.initialRegion)

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
            mapLayer

            VStack(alignment: .leading, spacing: CatureSpacing.lg) {
                titleSection
                filterRail
                Spacer()
                creatureCards
                bottomBar
            }
            .padding(.horizontal, CatureSpacing.lg)
            .padding(.top, CatureSpacing.xxl)
            .padding(.bottom, CatureSpacing.lg)
        }
        .task {
            await loadHomeData()
        }
    }

    private var mapLayer: some View {
        Map(position: $cameraPosition) {
            ForEach(creatures) { creature in
                Annotation("", coordinate: creature.coordinate) {
                    CreatureMarker(
                        creature: creature,
                        isSelected: creature.id == selectedCreatureId
                    )
                    .onTapGesture {
                        selectedCreatureId = creature.id
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .ignoresSafeArea()
        .overlay(CatureColor.surface.opacity(0.64).ignoresSafeArea())
    }

    private var titleSection: some View {
        Text("Cature")
            .font(CatureFont.largeTitle)
            .foregroundStyle(CatureColor.textPrimary)
            .padding(.top, CatureSpacing.xl)
    }

    private var filterRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: CatureSpacing.xs) {
                CircleButton(systemName: "plus")
                FilterChip(title: "Nearby", systemName: "mappin.and.ellipse", count: nil, isSelected: true)
                FilterChip(title: "Home", systemName: nil, count: 3, isSelected: false)
                FilterChip(title: "Office", systemName: nil, count: 6, isSelected: false)
                FilterChip(title: "Around", systemName: nil, count: 1, isSelected: false)
            }
            .padding(.trailing, CatureSpacing.lg)
        }
    }

    private var creatureCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: CatureSpacing.md) {
                ForEach(creatures) { creature in
                    CreatureCard(
                        creature: creature,
                        isSelected: creature.id == selectedCreatureId
                    )
                    .onTapGesture {
                        selectedCreatureId = creature.id
                        cameraPosition = .region(creature.focusRegion)
                    }
                }
            }
            .padding(.trailing, CatureSpacing.xxl)
        }
    }

    private var bottomBar: some View {
        HStack(alignment: .bottom, spacing: CatureSpacing.md) {
            HStack(spacing: CatureSpacing.lg) {
                BottomTab(systemName: "house.fill", title: "Home", isSelected: true)
                BottomTab(systemName: "checklist", title: nil, isSelected: false)
                BottomTab(systemName: "person.fill", title: nil, isSelected: false)
            }
            .padding(.horizontal, CatureSpacing.md)
            .padding(.vertical, CatureSpacing.sm)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(color: CatureColor.textSecondary.opacity(0.18), radius: 18, y: 10)

            Spacer()

            Button(action: {}) {
                Image(systemName: "camera.aperture")
                    .font(CatureFont.largeTitle)
                    .foregroundStyle(CatureColor.onFab)
                    .frame(width: 74, height: 74)
                    .background(CatureColor.fab)
                    .clipShape(Circle())
            }
        }
    }

    @MainActor
    private func loadHomeData() async {
        do {
            async let speciesResult = speciesRepository.allSpecies()
            async let entriesResult = collectionRepository.allEntries()
            async let sightingsResult = sightingRepository.allSightings()
            async let locationResult = locationService.currentLocation()

            let species = try await speciesResult
            let entries = try await entriesResult
            let sightings = try await sightingsResult
            let currentLocation = await locationResult

            let speciesById = Dictionary(uniqueKeysWithValues: species.map { ($0.id, $0) })
            let discovered = Set(entries.filter(\.discovered).map(\.speciesId))
            let visibleSightings = sightings.filter { sighting in
                discovered.contains(sighting.speciesId)
                    && sighting.latitude != nil
                    && sighting.longitude != nil
            }

            let mapped = visibleSightings.compactMap { sighting -> HomeCreature? in
                guard let species = speciesById[sighting.speciesId] else { return nil }
                return HomeCreature(
                    species: species,
                    sighting: sighting,
                    distanceText: Self.distanceText(from: currentLocation, to: sighting)
                )
            }

            creatures = mapped
            selectedCreatureId = mapped.first?.id
            if let first = mapped.first {
                cameraPosition = .region(first.focusRegion)
            }
        } catch {
            creatures = []
            selectedCreatureId = nil
        }
    }

    private static let initialRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
        span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
    )

    private static func distanceText(from location: LocationSample?, to sighting: Sighting) -> String {
        guard
            let location,
            let latitude = sighting.latitude,
            let longitude = sighting.longitude
        else {
            return "거리 확인 중"
        }

        let current = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let target = CLLocation(latitude: latitude, longitude: longitude)
        let meters = current.distance(from: target)

        if meters >= 1_000 {
            return "\(String(format: "%.1f", meters / 1_000))km"
        }
        return "\(Int(meters.rounded()))m"
    }
}

private struct HomeCreature: Identifiable, Hashable {
    let species: Species
    let sighting: Sighting
    let distanceText: String

    var id: String { sighting.id }
    var title: String { displayName(for: species) }
    var subtitle: String { species.nameKo }
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: sighting.latitude ?? 37.5665,
            longitude: sighting.longitude ?? 126.9780
        )
    }
    var focusRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
        )
    }
    var markerSymbol: String {
        switch species.id {
        case "chameleon": "leaf.fill"
        case "tree_frog": "leaf.fill"
        case "ladybug": "ladybug.fill"
        case "cat": "cat.fill"
        default: "pawprint.fill"
        }
    }

    private func displayName(for species: Species) -> String {
        switch species.id {
        case "chameleon": "Chameleon"
        case "tree_frog": "Tree frog"
        case "ladybug": "Ladybug"
        case "cat": "Cat"
        default: species.nameKo
        }
    }
}

private struct CreatureMarker: View {
    let creature: HomeCreature
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(isSelected ? CatureColor.accentSoft : CatureColor.surfaceSecondary)
                Circle()
                    .stroke(CatureColor.surface, lineWidth: 6)
                Image(systemName: creature.markerSymbol)
                    .font(CatureFont.largeTitle)
                    .foregroundStyle(isSelected ? CatureColor.accent : CatureColor.textSecondary)
            }
            .frame(width: isSelected ? 96 : 88, height: isSelected ? 96 : 88)
            .shadow(color: CatureColor.textSecondary.opacity(0.18), radius: 16, y: 8)

            Text(creature.subtitle)
                .font(CatureFont.callout.weight(.bold))
                .foregroundStyle(CatureColor.darkTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .padding(.horizontal, CatureSpacing.sm)
                .padding(.vertical, CatureSpacing.xs)
                .background(CatureColor.fab.opacity(0.78))
                .clipShape(Capsule())
                .overlay(alignment: .bottom) {
                    Triangle()
                        .fill(CatureColor.fab.opacity(0.78))
                        .frame(width: 16, height: 10)
                        .offset(y: 9)
                }
        }
    }
}

private struct CreatureCard: View {
    let creature: HomeCreature
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .center, spacing: CatureSpacing.md) {
            VStack(alignment: .leading, spacing: CatureSpacing.xs) {
                Text(creature.title)
                    .font(CatureFont.largeTitle)
                    .foregroundStyle(CatureColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(creature.subtitle)
                    .font(CatureFont.headline)
                    .foregroundStyle(CatureColor.textSecondary)

                Spacer(minLength: CatureSpacing.xs)

                Text("보유중")
                    .font(CatureFont.caption.weight(.bold))
                    .foregroundStyle(CatureColor.onFab)
                    .padding(.horizontal, CatureSpacing.sm)
                    .padding(.vertical, CatureSpacing.xs)
                    .background(CatureColor.fab)
                    .clipShape(Capsule())

                Text("\(creature.distanceText) · 발견 확률 높음")
                    .font(CatureFont.callout)
                    .foregroundStyle(CatureColor.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: CatureSpacing.sm)

            ZStack {
                Circle()
                    .fill(CatureColor.accentSoft)
                Image(systemName: creature.markerSymbol)
                    .font(CatureFont.largeTitle)
                    .foregroundStyle(CatureColor.accent)
            }
            .frame(width: 118, height: 118)
        }
        .padding(CatureSpacing.lg)
        .frame(width: 312, height: 150)
        .background(isSelected ? CatureColor.accentSoft : CatureColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: CatureRadius.card, style: .continuous))
        .shadow(color: CatureColor.textSecondary.opacity(isSelected ? 0.18 : 0.10), radius: 18, y: 8)
    }
}

private struct FilterChip: View {
    let title: String
    let systemName: String?
    let count: Int?
    let isSelected: Bool

    var body: some View {
        HStack(spacing: CatureSpacing.xs) {
            if let systemName {
                Image(systemName: systemName)
                    .font(CatureFont.callout.weight(.semibold))
            }
            if let count {
                Text("\(count)")
                    .font(CatureFont.callout.weight(.semibold))
                    .foregroundStyle(CatureColor.textSecondary)
                    .frame(width: 26, height: 26)
                    .background(CatureColor.surface)
                    .clipShape(Circle())
            }
            Text(title)
                .font(CatureFont.headline)
                .lineLimit(1)
        }
        .foregroundStyle(CatureColor.textPrimary)
        .padding(.horizontal, CatureSpacing.md)
        .frame(height: 56)
        .background(isSelected ? CatureColor.accentSoft : CatureColor.surface.opacity(0.94))
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(CatureColor.surfaceSecondary, lineWidth: isSelected ? 0 : 1)
        }
        .shadow(color: CatureColor.textSecondary.opacity(0.10), radius: 8, y: 3)
    }
}

private struct CircleButton: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(CatureFont.title)
            .foregroundStyle(CatureColor.textPrimary)
            .frame(width: 56, height: 56)
            .background(CatureColor.surface)
            .clipShape(Circle())
            .shadow(color: CatureColor.textSecondary.opacity(0.12), radius: 8, y: 3)
    }
}

private struct BottomTab: View {
    let systemName: String
    let title: String?
    let isSelected: Bool

    var body: some View {
        HStack(spacing: CatureSpacing.xs) {
            Image(systemName: systemName)
                .font(CatureFont.title)
            if let title {
                Text(title)
                    .font(CatureFont.headline)
            }
        }
        .foregroundStyle(isSelected ? CatureColor.textPrimary : CatureColor.textSecondary)
        .frame(width: isSelected ? 152 : 52, height: 58)
        .background(isSelected ? CatureColor.surface : Color.clear)
        .clipShape(Capsule())
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

private enum HomePreviewData {
    static var creature: HomeCreature {
        HomeCreature(
            species: Species(id: "chameleon", nameKo: "카멜레온", category: "파충류", usdzAsset: "chameleon.usdz", thumbnail: "chameleon"),
            sighting: Sighting(
                id: "preview-chameleon",
                speciesId: "chameleon",
                photoPath: "mock/chameleon.jpg",
                latitude: 37.5661,
                longitude: 126.9768,
                locationName: "Nearby",
                createdAt: Date(timeIntervalSinceReferenceDate: 783_648_000)
            ),
            distanceText: "120m"
        )
    }

    static var collectionRepository: MockCollectionRepository {
        let now = Date(timeIntervalSinceReferenceDate: 783_648_000)
        return MockCollectionRepository(entries: [
            CollectionEntry(speciesId: "chameleon", captureCount: 2, discovered: true, firstSeenAt: now, lastSeenAt: now, isFavorite: true),
            CollectionEntry(speciesId: "tree_frog", captureCount: 1, discovered: true, firstSeenAt: now, lastSeenAt: now, isFavorite: false),
            CollectionEntry(speciesId: "ladybug", captureCount: 1, discovered: true, firstSeenAt: now, lastSeenAt: now, isFavorite: false),
        ])
    }

    static var sightingRepository: MockSightingRepository {
        let now = Date(timeIntervalSinceReferenceDate: 783_648_000)
        return MockSightingRepository(sightings: [
            Sighting(id: "home-chameleon", speciesId: "chameleon", photoPath: "mock/chameleon.jpg", latitude: 37.5661, longitude: 126.9768, locationName: "Nearby", createdAt: now),
            Sighting(id: "home-tree-frog", speciesId: "tree_frog", photoPath: "mock/tree-frog.jpg", latitude: 37.5671, longitude: 126.9788, locationName: "Office", createdAt: now),
            Sighting(id: "home-ladybug", speciesId: "ladybug", photoPath: "mock/ladybug.jpg", latitude: 37.5652, longitude: 126.9793, locationName: "Home", createdAt: now),
        ])
    }
}

#Preview {
    RootView(
        collectionRepository: HomePreviewData.collectionRepository,
        sightingRepository: HomePreviewData.sightingRepository,
        speciesRepository: MockSpeciesRepository(),
        locationService: MockLocationService(
            sample: LocationSample(latitude: 37.5665, longitude: 126.9780, locationName: "서울특별시 중구")
        )
    )
}

#Preview("Creature Marker") {
    CreatureMarker(creature: HomePreviewData.creature, isSelected: true)
}

#Preview("Creature Card") {
    CreatureCard(creature: HomePreviewData.creature, isSelected: true)
        .padding(CatureSpacing.lg)
}

#Preview("Filter Chip") {
    HStack {
        CircleButton(systemName: "plus")
        FilterChip(title: "Nearby", systemName: "mappin.and.ellipse", count: nil, isSelected: true)
        FilterChip(title: "Home", systemName: nil, count: 3, isSelected: false)
    }
    .padding(CatureSpacing.lg)
}

#Preview("Bottom Tab") {
    HStack {
        BottomTab(systemName: "house.fill", title: "Home", isSelected: true)
        BottomTab(systemName: "checklist", title: nil, isSelected: false)
        BottomTab(systemName: "person.fill", title: nil, isSelected: false)
    }
    .padding(CatureSpacing.lg)
}
