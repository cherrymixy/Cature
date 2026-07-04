//  DiscoveryFlowTests.swift
//  발견 플로우 상태 전이 검증(Mock 주입). UI 없이 로직만.

import Testing
import CorePackage
@testable import DiscoveryFeature

@MainActor
@Suite("발견 플로우")
struct DiscoveryFlowTests {

    @Test("촬영 → 후보 → 선택 → 공존 → 저장 → 수집")
    func fullFlow() async {
        let vm = DiscoveryViewModel(deps: .mock)
        guard case .camera = vm.step else { Issue.record("초기는 camera"); return }

        await vm.capture()
        guard case let .candidates(candidates) = vm.step else { Issue.record("candidates 기대"); return }
        #expect(candidates.count == 3)
        #expect(candidates.first?.displayName == "카멜레온")

        await vm.select(candidates[0])   // 카멜레온
        guard case let .coexist(card, species, _) = vm.step else { Issue.record("coexist 기대"); return }
        #expect(species?.nameKo == "카멜레온")
        #expect(!card.needs.isEmpty)

        await vm.save()
        guard case let .collected(name, count, achievement, canExperience) = vm.step else { Issue.record("collected 기대"); return }
        #expect(name == "카멜레온")
        #expect(count == 1)
        #expect(canExperience)          // usdz 보유
        #expect(achievement > 0)        // 발견 1 / 전체 4
    }

    @Test("비큐레이션 후보(speciesId=nil) 선택 → notFound")
    func nonCuratedCandidate() async {
        let vm = DiscoveryViewModel(deps: .mock)
        await vm.capture()
        guard case let .candidates(candidates) = vm.step,
              let mushroom = candidates.first(where: { $0.speciesId == nil }) else {
            Issue.record("버섯 후보 없음"); return
        }
        await vm.select(mushroom)
        guard case .notFound = vm.step else { Issue.record("notFound 기대"); return }
    }

    @Test("다시 찍기 → camera")
    func retake() async {
        let vm = DiscoveryViewModel(deps: .mock)
        await vm.capture()
        vm.retake()
        guard case .camera = vm.step else { Issue.record("camera 기대"); return }
    }
}
