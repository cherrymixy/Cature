import CoreLocation
import CorePackage
import DesignTokens
import SwiftUI

public struct RootView: View {
    private let collectionRepository: any CollectionRepository
    private let sightingRepository: any SightingRepository
    private let speciesRepository: any SpeciesRepository
    private let locationService: any LocationService

    @State private var discoveredCount = 0
    @State private var distanceText = "120m"

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
        GeometryReader { geometry in
            let size = geometry.size
            let scale = max(size.width / Figma.baseWidth, size.height / Figma.baseHeight)
            let canvas = CGSize(width: size.width / scale, height: size.height / scale)

            ZStack(alignment: .topLeading) {
                Image("home-map", bundle: .module)
                    .resizable()
                    .scaledToFill()
                    .frame(width: Figma.mapWidth, height: Figma.mapHeight)
                    .rotationEffect(.degrees(90))
                    .opacity(0.5)
                    .position(x: 221, y: 299)

                LinearGradient(
                    colors: [
                        CatureColor.accentSoft.opacity(0.7),
                        CatureColor.surface.opacity(0.0),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: Figma.baseWidth, height: 266)
                .position(x: Figma.baseWidth / 2, y: 132)

                Text("Cature")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(CatureColor.textPrimary.opacity(0.9))
                    .kerning(-3.36)
                    .position(x: 97, y: 104)

                categoryRail(discoveredCount: discoveredCount)
                    .position(x: 224, y: 152)

                FigmaMarker(assetName: "marker-chameleon", label: "카멜레온")
                    .position(x: 91, y: 304)

                FigmaMarker(assetName: "marker-tree", label: "은행나무")
                    .position(x: 286, y: 348)

                FigmaMarker(assetName: "marker-duck", label: "청둥오리")
                    .position(x: 230, y: 502)

                cardRail(distanceText: distanceText)
                    .position(x: 298, y: 672)

                bottomNavigation
                    .position(x: 212, y: 788)
            }
            .frame(width: canvas.width, height: canvas.height)
            .scaleEffect(scale, anchor: .topLeading)
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .background(CatureColor.surface)
            .clipped()
            .ignoresSafeArea()
        }
        .task {
            await loadMockBackedState()
        }
    }

    private func categoryRail(discoveredCount: Int) -> some View {
        HStack(spacing: 5) {
            CircleButton(systemName: "plus")
            CategoryChip(title: "Nearby", systemName: "mappin.and.ellipse", count: nil, isSelected: true)
            CategoryChip(title: "Home", systemName: nil, count: max(discoveredCount, 3), isSelected: false)
            CategoryChip(title: "Office", systemName: nil, count: 6, isSelected: false)
            CategoryChip(title: "Addxd", systemName: nil, count: 1, isSelected: false)
        }
        .frame(height: 38)
    }

    private func cardRail(distanceText: String) -> some View {
        HStack(spacing: 16) {
            CreatureCard(isSelected: true, distanceText: distanceText)
            CreatureCard(isSelected: false, distanceText: distanceText)
        }
    }

    private var bottomNavigation: some View {
        HStack(spacing: 14) {
            HStack(spacing: 15) {
                BottomTab(systemName: "house.fill", title: "Home", isSelected: true)
                BottomTab(systemName: "checklist", title: nil, isSelected: false)
                BottomTab(systemName: "person.fill", title: nil, isSelected: false)
            }
            .frame(width: 262, height: 58)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(CatureColor.surface)
                    .frame(width: 122, height: 58)
                    .shadow(color: CatureColor.textSecondary.opacity(0.08), radius: 9, x: -1, y: 1)
            }
            .overlay(alignment: .leading) {
                BottomTab(systemName: "house.fill", title: "Home", isSelected: true)
                    .frame(width: 122, height: 58)
            }
            .shadow(color: CatureColor.textSecondary.opacity(0.08), radius: 13, y: 2)

            CameraButton()
        }
    }

    @MainActor
    private func loadMockBackedState() async {
        do {
            async let entriesResult = collectionRepository.allEntries()
            async let sightingsResult = sightingRepository.allSightings()
            async let locationResult = locationService.currentLocation()
            _ = try await speciesRepository.allSpecies()

            let entries = try await entriesResult
            let sightings = try await sightingsResult
            let currentLocation = await locationResult

            discoveredCount = max(entries.filter(\.discovered).count, 3)

            guard
                let currentLocation,
                let first = sightings.first(where: { $0.latitude != nil && $0.longitude != nil }),
                let latitude = first.latitude,
                let longitude = first.longitude
            else {
                distanceText = "120m"
                return
            }

            let current = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
            let target = CLLocation(latitude: latitude, longitude: longitude)
            let meters = Int(current.distance(from: target).rounded())
            distanceText = meters > 0 ? "\(meters)m" : "120m"
        } catch {
            discoveredCount = 3
            distanceText = "120m"
        }
    }
}

private enum Figma {
    static let baseWidth: CGFloat = 393
    static let baseHeight: CGFloat = 852
    static let mapWidth: CGFloat = 959.493
    static let mapHeight: CGFloat = 753.202
}

private struct CategoryChip: View {
    let title: String
    let systemName: String?
    let count: Int?
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 5) {
            if let systemName {
                Image(systemName: systemName)
                    .font(.system(size: 13, weight: .medium))
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
                .foregroundStyle(isSelected ? CatureColor.textPrimary : CatureColor.textPrimary.opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, isSelected ? 18 : 10)
        .frame(width: isSelected ? 104 : 86, height: 38)
        .background(isSelected ? CatureColor.accentSoft.opacity(2.5) : CatureColor.surface)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(CatureColor.textPrimary.opacity(isSelected ? 0 : 0.1), lineWidth: 1)
        }
    }
}

private struct CircleButton: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 20, weight: .regular))
            .foregroundStyle(CatureColor.textPrimary)
            .frame(width: 38, height: 38)
            .background(CatureColor.surface)
            .clipShape(Circle())
    }
}

private struct FigmaMarker: View {
    let assetName: String
    let label: String

    var body: some View {
        VStack(spacing: -6) {
            Image(assetName, bundle: .module)
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)

            Text(label)
                .font(.system(size: 12.3, weight: .medium))
                .foregroundStyle(CatureColor.onFab)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 9)
                .frame(height: 31, alignment: .top)
                .padding(.top, 4)
                .background {
                    MarkerLabelShape()
                        .fill(CatureColor.fab.opacity(0.78))
                        .frame(width: 60, height: 31)
                }
        }
        .frame(width: 88)
    }
}

private struct MarkerLabelShape: Shape {
    func path(in rect: CGRect) -> Path {
        let pointerHeight: CGFloat = 8
        let capsule = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - pointerHeight)
        var path = Path()
        path.addRoundedRect(in: capsule, cornerSize: CGSize(width: 15, height: 15))
        path.move(to: CGPoint(x: rect.midX - 8, y: capsule.maxY - 1))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX + 8, y: capsule.maxY - 1))
        path.closeSubpath()
        return path
    }
}

private struct CreatureCard: View {
    let isSelected: Bool
    let distanceText: String

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            VStack(alignment: .leading, spacing: 15) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Chameleon")
                        .font(.system(size: 28, weight: .semibold))
                        .kerning(-1.96)
                        .foregroundStyle(CatureColor.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text("카멜레온")
                        .font(.system(size: 14, weight: .medium))
                        .kerning(-0.7)
                        .foregroundStyle(CatureColor.textPrimary.opacity(0.5))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("보유중")
                        .font(.system(size: 11.3, weight: .medium))
                        .foregroundStyle(CatureColor.onFab)
                        .frame(width: 48, height: 18)
                        .background(CatureColor.fab)
                        .clipShape(Capsule())

                    Text("\(distanceText) · 발견 확률 높음")
                        .font(.system(size: 12.7, weight: .medium))
                        .kerning(-0.38)
                        .foregroundStyle(CatureColor.textPrimary.opacity(0.5))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .frame(width: 131, alignment: .leading)

            Spacer(minLength: 0)

            Image("card-chameleon", bundle: .module)
                .resizable()
                .scaledToFill()
                .frame(width: 101, height: 104)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .scaleEffect(x: -1, y: -1)
                .rotationEffect(.degrees(180))
        }
        .padding(.top, 16)
        .padding(.leading, 16)
        .padding(.trailing, 18)
        .padding(.bottom, 13)
        .frame(width: 282, height: 133)
        .background(isSelected ? CatureColor.accentSoft.opacity(2.5) : CatureColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: CatureColor.textSecondary.opacity(isSelected ? 0.05 : 0.04), radius: isSelected ? 6 : 2)
    }
}

private struct BottomTab: View {
    let systemName: String
    let title: String?
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: systemName)
                .font(.system(size: 23, weight: .bold))
            if let title {
                Text(title)
                    .font(.system(size: 15.2, weight: .medium))
                    .kerning(-0.46)
            }
        }
        .foregroundStyle(isSelected ? CatureColor.textPrimary : CatureColor.textSecondary)
        .frame(width: isSelected ? 122 : 52, height: 58)
    }
}

private struct CameraButton: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(CatureColor.fab)
                .frame(width: 58, height: 58)

            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(CatureColor.onFab)
                    .frame(width: 12, height: 27)
                    .rotationEffect(.degrees(Double(index) * 90 + 45))
                    .offset(y: -11)
                    .rotationEffect(.degrees(Double(index) * 90))
            }
        }
    }
}

private enum HomePreviewData {
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
            Sighting(id: "home-chameleon", speciesId: "chameleon", photoPath: "mock/chameleon.jpg", latitude: 37.5655, longitude: 126.9774, locationName: "Nearby", createdAt: now),
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

#Preview("Marker") {
    FigmaMarker(assetName: "marker-chameleon", label: "카멜레온")
        .padding()
}

#Preview("Card") {
    CreatureCard(isSelected: true, distanceText: "120m")
        .padding()
}

#Preview("Categories") {
    HStack(spacing: 5) {
        CircleButton(systemName: "plus")
        CategoryChip(title: "Nearby", systemName: "mappin.and.ellipse", count: nil, isSelected: true)
        CategoryChip(title: "Home", systemName: nil, count: 3, isSelected: false)
    }
    .padding()
}

#Preview("Bottom Navigation") {
    HStack {
        BottomTab(systemName: "house.fill", title: "Home", isSelected: true)
        BottomTab(systemName: "checklist", title: nil, isSelected: false)
        BottomTab(systemName: "person.fill", title: nil, isSelected: false)
        CameraButton()
    }
    .padding()
}
