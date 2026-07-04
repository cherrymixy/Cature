import CorePackage
import DesignTokens
import SwiftUI

public struct RootView: View {
    private let profileRepository: any ProfileRepository

    public init(profileRepository: any ProfileRepository = MockProfileRepository()) {
        self.profileRepository = profileRepository
    }

    public var body: some View {
        Text("온보딩")
            .font(CatureFont.title)
            .foregroundStyle(CatureColor.textPrimary)
    }
}

#Preview {
    RootView(profileRepository: MockProfileRepository())
}
