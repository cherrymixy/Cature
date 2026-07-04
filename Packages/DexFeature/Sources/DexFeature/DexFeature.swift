//  DexFeature.swift
//  Cature — 도감/마이 (찬희). G1 이후.
//
//  스캐폴드 골격(S0). 아직 로직 없음.

import CorePackage
import SwiftUI

public struct RootView: View {
    private let collectionRepository: any CollectionRepository
    private let speciesRepository: any SpeciesRepository
    private let profileRepository: any ProfileRepository

    public init(
        collectionRepository: any CollectionRepository = MockCollectionRepository(),
        speciesRepository: any SpeciesRepository = MockSpeciesRepository(),
        profileRepository: any ProfileRepository = MockProfileRepository()
    ) {
        self.collectionRepository = collectionRepository
        self.speciesRepository = speciesRepository
        self.profileRepository = profileRepository
    }

    public var body: some View {
        Text("도감")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if !CLI_BUILD
#Preview {
    RootView()
}
#endif
