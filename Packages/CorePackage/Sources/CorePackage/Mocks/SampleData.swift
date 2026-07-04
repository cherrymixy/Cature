//  SampleData.swift
//  CorePackage/Mocks — 팀원 mock-first 개발용 시드 데이터.

import Foundation

/// Mock 구현이 쓰는 고정 시드. 실데이터는 data/ + Data/Services 실구현에서.
public enum SampleData {

    /// 큐레이션 씨앗 종 (usdz 없는 종 = AR 체험 비활성 예시 포함).
    public static let species: [Species] = [
        Species(id: "cat",       nameKo: "고양이",    category: "포유류", usdzAsset: "cat.usdz",       thumbnail: "cat"),
        Species(id: "chameleon", nameKo: "카멜레온",  category: "파충류", usdzAsset: "chameleon.usdz", thumbnail: "chameleon"),
        Species(id: "lizard",    nameKo: "도마뱀",    category: "파충류", usdzAsset: "lizard.usdz",    thumbnail: "lizard"),
        Species(id: "tree_frog", nameKo: "청개구리",  category: "양서류", usdzAsset: "tree_frog.usdz", thumbnail: "tree_frog"),
        Species(id: "ladybug",   nameKo: "무당벌레",  category: "곤충",   usdzAsset: nil,              thumbnail: "ladybug"),
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
}
