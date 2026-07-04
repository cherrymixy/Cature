//  MinigameFeature.swift
//  Cature — 미니게임: 카드 뒤집기→가위바위보 (찬희). G1 이후.
//
//  스캐폴드 골격(S0). 아직 로직 없음.

import CorePackage
import SwiftUI

public struct RootView: View {
    private let collectionRepository: any CollectionRepository
    private let speciesRepository: any SpeciesRepository

    public init(
        collectionRepository: any CollectionRepository = MockCollectionRepository(),
        speciesRepository: any SpeciesRepository = MockSpeciesRepository()
    ) {
        self.collectionRepository = collectionRepository
        self.speciesRepository = speciesRepository
    }

    public var body: some View {
        Text("기능")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
