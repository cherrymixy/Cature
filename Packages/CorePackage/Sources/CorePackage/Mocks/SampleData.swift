//  SampleData.swift
//  CorePackage/Mocks — 팀원 mock-first 개발용 시드 데이터.

import Foundation

/// Mock 구현이 쓰는 고정 시드. 실데이터는 data/ + Data/Services 실구현에서.
public enum SampleData {

    /// 큐레이션 씨앗 종 (usdz 없는 종 = AR 체험 비활성 예시 포함).
    public static let species: [Species] = [
        Species(id: "cat",       nameKo: "고양이",    category: "포유류", usdzAsset: "cat.usdz",       thumbnail: "cat"),
        Species(id: "chameleon", nameKo: "카멜레온",  category: "파충류", usdzAsset: "Newt.usdz", thumbnail: "chameleon"),
        Species(id: "lizard",    nameKo: "도마뱀",    category: "파충류", usdzAsset: "lizard.usdz",    thumbnail: "lizard"),
        Species(id: "tree_frog", nameKo: "청개구리",  category: "양서류", usdzAsset: "tree_frog.usdz", thumbnail: "tree_frog"),
        Species(id: "ladybug",   nameKo: "무당벌레",  category: "곤충",   usdzAsset: nil,              thumbnail: "ladybug"),
        Species(id: "chicken",   nameKo: "닭",        category: "조류",   usdzAsset: nil,              thumbnail: "chicken"),
        Species(id: "tree",      nameKo: "느티나무",  category: "식물",   usdzAsset: nil,              thumbnail: "tree"),
        Species(id: "duck",      nameKo: "청둥오리",  category: "조류",   usdzAsset: nil,              thumbnail: "duck"),
        Species(id: "ant",       nameKo: "개미",      category: "곤충",   usdzAsset: nil,              thumbnail: "ant"),
        Species(id: "bee",       nameKo: "벌",        category: "곤충",   usdzAsset: nil,              thumbnail: "bee"),
        Species(id: "fly",       nameKo: "파리",      category: "곤충",   usdzAsset: nil,              thumbnail: "fly"),
        Species(id: "cactus",    nameKo: "선인장",    category: "식물",   usdzAsset: nil,              thumbnail: "cactus"),
        Species(id: "dracaena",  nameKo: "드라세나",  category: "식물",   usdzAsset: nil,              thumbnail: "dracaena"),
        Species(id: "mushroom",  nameKo: "야생버섯",  category: "균류",   usdzAsset: nil,              thumbnail: "mushroom"),
    ]

    /// MockLLMService.identify 고정 후보 (플레이북 S1: 카멜레온 0.78 / 도마뱀 0.24 / 버섯 0.02).
    public static let identifyCandidates: [AnalysisCandidate] = [
        AnalysisCandidate(speciesId: "chameleon", displayName: "카멜레온", confidence: 0.78, category: "동물"),
        AnalysisCandidate(speciesId: "lizard",    displayName: "도마뱀",   confidence: 0.24, category: "동물"),
        AnalysisCandidate(speciesId: nil,         displayName: "버섯",     confidence: 0.02, category: "식물"),
    ]

    /// 카멜레온 검수 공존 카드 (플레이북 S1 샘플).
    public static let chameleonCard = CoexistCard(
        speciesId: "chameleon",
        intro: "느리게 움직이며 주변에 몸 색을 맞추는 나무 위 사냥꾼이에요.",
        needs: ["붙잡을 나뭇가지", "몸을 숨길 은신처", "햇볕과 그늘"],
        disturbances: ["손으로 만지기", "오래 촬영하며 따라다니기"],
        source: .curated
    )

    /// 고양이 검수 공존 카드 (데모 실 에셋 = cat.usdz).
    public static let catCard = CoexistCard(
        speciesId: "cat",
        intro: "사람 곁에서 살아가는 영리하고 독립적인 동물이에요.",
        needs: ["안전하게 쉴 공간", "깨끗한 물과 먹이", "몸을 숨길 높은 자리"],
        disturbances: ["갑자기 껴안거나 붙잡기", "큰 소리로 놀래기"],
        source: .curated
    )

    /// 비큐레이션/미캐시 종의 기본 공존 카드 폴백.
    public static func fallbackCard(speciesId: String) -> CoexistCard {
        CoexistCard(
            speciesId: speciesId,
            intro: "이 생명에 대해 조금 더 알아가 볼까요?",
            needs: ["안전한 서식 공간", "먹이와 물"],
            disturbances: ["갑작스러운 접근", "서식지 훼손"],
            source: .llm
        )
    }

    // MARK: - 홈 지도 데모 (장소 필터)

    /// 홈 지도 필터 장소. 각 장소 근처에 데모 발견이 있고, 칩 탭 시 그 장소로 이동·필터.
    public struct DemoPlace: Identifiable, Sendable {
        public let id: String
        public let title: String
        public let latitude: Double
        public let longitude: Double
        public init(id: String, title: String, latitude: Double, longitude: Double) {
            self.id = id; self.title = title; self.latitude = latitude; self.longitude = longitude
        }
    }

    public static let demoPlaces: [DemoPlace] = [
        DemoPlace(id: "home",   title: "Home",   latitude: 37.5133, longitude: 127.1000),  // 잠실
        DemoPlace(id: "office", title: "Office", latitude: 37.5476, longitude: 126.9227),  // 상수역
        DemoPlace(id: "addxd",  title: "Addxd",  latitude: 36.4808, longitude: 127.2890),  // 세종
    ]

    private static func demoDate(_ offset: Int) -> Date {
        Date(timeIntervalSince1970: 1_720_000_000 + Double(offset) * 3600)
    }

    /// 데모 발견: Home(잠실) 4 · Office(상수역) 6 · Addxd(세종) 1 = 11건. 모두 이미지 있는 종.
    public static let demoSightings: [Sighting] = [
        // Home — 잠실 (4)
        Sighting(id: "home-cat",     speciesId: "cat",     photoPath: "", latitude: 37.5142, longitude: 127.1008, locationName: "잠실", createdAt: demoDate(0)),
        Sighting(id: "home-chicken", speciesId: "chicken", photoPath: "", latitude: 37.5126, longitude: 127.0987, locationName: "잠실", createdAt: demoDate(1)),
        Sighting(id: "home-duck",    speciesId: "duck",    photoPath: "", latitude: 37.5148, longitude: 127.0994, locationName: "잠실", createdAt: demoDate(2)),
        Sighting(id: "home-ladybug", speciesId: "ladybug", photoPath: "", latitude: 37.5121, longitude: 127.1013, locationName: "잠실", createdAt: demoDate(3)),
        // Office — 상수역 (6)
        Sighting(id: "office-chameleon", speciesId: "chameleon", photoPath: "", latitude: 37.5485, longitude: 126.9235, locationName: "상수역", createdAt: demoDate(4)),
        Sighting(id: "office-tree",      speciesId: "tree",      photoPath: "", latitude: 37.5468, longitude: 126.9216, locationName: "상수역", createdAt: demoDate(5)),
        Sighting(id: "office-ant",       speciesId: "ant",       photoPath: "", latitude: 37.5491, longitude: 126.9210, locationName: "상수역", createdAt: demoDate(6)),
        Sighting(id: "office-bee",       speciesId: "bee",       photoPath: "", latitude: 37.5463, longitude: 126.9241, locationName: "상수역", createdAt: demoDate(7)),
        Sighting(id: "office-fly",       speciesId: "fly",       photoPath: "", latitude: 37.5481, longitude: 126.9251, locationName: "상수역", createdAt: demoDate(8)),
        Sighting(id: "office-cactus",    speciesId: "cactus",    photoPath: "", latitude: 37.5471, longitude: 126.9203, locationName: "상수역", createdAt: demoDate(9)),
        // Addxd — 세종 (1)
        Sighting(id: "addxd-mushroom",   speciesId: "mushroom",  photoPath: "", latitude: 36.4812, longitude: 127.2896, locationName: "세종", createdAt: demoDate(10)),
    ]

    /// demoSightings에 대응하는 수집 엔트리(발견=보유중 처리).
    public static let demoEntries: [CollectionEntry] = demoSightings.map {
        CollectionEntry(
            speciesId: $0.speciesId, captureCount: 1, discovered: true,
            firstSeenAt: $0.createdAt, lastSeenAt: $0.createdAt, isFavorite: false
        )
    }
}
