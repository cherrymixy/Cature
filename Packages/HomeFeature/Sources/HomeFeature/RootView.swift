import CorePackage
import DesignTokens
import SwiftUI

public struct RootView: View {
    private let collectionRepository: any CollectionRepository
    private let sightingRepository: any SightingRepository
    private let speciesRepository: any SpeciesRepository
    private let locationService: any LocationService

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
        Text("홈")
            .font(CatureFont.title)
            .foregroundStyle(CatureColor.textPrimary)
    }
}

#Preview {
    RootView(
        collectionRepository: MockCollectionRepository(),
        sightingRepository: MockSightingRepository(),
        speciesRepository: MockSpeciesRepository(),
        locationService: MockLocationService()
    )
}
