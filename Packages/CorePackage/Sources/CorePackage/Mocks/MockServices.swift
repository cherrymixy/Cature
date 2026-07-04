//  MockServices.swift
//  CorePackage/Mocks — LLM·위치·캡처 서비스 목.

import Foundation

/// 고정 후보/카드를 반환하는 LLM 목.
public struct MockLLMService: LLMService {
    public init() {}

    public func identify(image: Data) async throws -> [AnalysisCandidate] {
        SampleData.identifyCandidates
    }

    public func coexistCard(speciesId: String) async throws -> CoexistCard {
        speciesId == "chameleon" ? SampleData.chameleonCard : SampleData.fallbackCard(speciesId: speciesId)
    }
}

/// 고정 좌표를 반환하는 위치 목. `sample`을 nil로 주면 "권한 거부" 시뮬레이션.
public struct MockLocationService: LocationService {
    public let sample: LocationSample?

    public init(sample: LocationSample? = LocationSample(latitude: 37.5665, longitude: 126.9780, locationName: "서울특별시 중구")) {
        self.sample = sample
    }

    public func currentLocation() async -> LocationSample? { sample }
}

/// 빈 임시 파일을 만들어 URL을 반환하는 캡처 목.
public struct MockCaptureService: CaptureService {
    public init() {}

    public func capturePhoto() async throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("mock-capture-\(UUID().uuidString).jpg")
        try Data().write(to: url)
        return url
    }
}
