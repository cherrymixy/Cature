//  CollectionMath.swift
//  CorePackage — 수집 규칙(순수 함수). 테스트로 얼린다.

/// 도감/수집 계산 규칙(PRD §3).
public enum CollectionMath {
    /// 달성률 = 발견(discovered) 종수 ÷ 도감 대상 종수. 결과는 0...1.
    /// 대상 종수 0이면 0. (촬영 N회 승격이 아니라 "저장 1회 = 등재" 기본값.)
    public static func achievement(discoveredCount: Int, totalSpecies: Int) -> Double {
        guard totalSpecies > 0 else { return 0 }
        return min(1, Double(discoveredCount) / Double(totalSpecies))
    }
}
