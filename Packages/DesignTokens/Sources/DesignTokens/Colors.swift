//  Colors.swift
//  DesignTokens — Cature 색 토큰 (PRD §7). 하드코딩 금지, 여기로만 접근.
//
//  라이트 컨텍스트 = 홈·지도(화이트/뉴트럴). 다크 컨텍스트 = 카메라·분석·공존카드·수집연출·체험(딥그레이/블랙).
//  값은 임시(디자인 확정 전)지만 접근은 항상 토큰으로.

import SwiftUI

/// 화면 컨텍스트. Cature는 지도=라이트 / 카메라 계열=다크로 톤을 나눈다.
public enum CatureAppearance: Sendable {
    case light   // 홈·지도
    case dark    // 카메라·분석·공존카드·수집연출·체험
}

public enum CatureColor {

    // MARK: Brand
    /// 메인 브랜드 라임 #F4FE7D (앱 AccentColor와 동일).
    public static let accent = Color(red: 0.957, green: 0.996, blue: 0.490)
    public static let accentSoft = Color(red: 0.957, green: 0.996, blue: 0.490).opacity(0.15)
    /// Figma 하이라이트 라임 (#f4fe7d)
    public static let lime = Color(red: 0.957, green: 0.996, blue: 0.490)
    /// 어두운 버튼/잉크 (#282828)
    public static let ink = Color(red: 0.157, green: 0.157, blue: 0.157)

    // MARK: Light context (홈·지도)
    public static let surface = Color(red: 1.00, green: 1.00, blue: 1.00)
    public static let surfaceSecondary = Color(red: 0.95, green: 0.96, blue: 0.96)
    public static let textPrimary = Color(red: 0.09, green: 0.11, blue: 0.11)
    public static let textSecondary = Color(red: 0.45, green: 0.47, blue: 0.47)

    // MARK: Dark context (카메라 계열)
    public static let darkSurface = Color(red: 0.07, green: 0.08, blue: 0.09)
    public static let darkSurfaceElevated = Color(red: 0.13, green: 0.14, blue: 0.16)
    public static let darkTextPrimary = Color(red: 0.96, green: 0.97, blue: 0.97)
    public static let darkTextSecondary = Color(red: 0.66, green: 0.68, blue: 0.70)

    // MARK: FAB (라이트 화면 위 다크 원형 카메라 버튼) — Figma #0d0f18
    public static let fab = Color(red: 0.051, green: 0.059, blue: 0.094)
    public static let onFab = Color.white

    // MARK: 지도 마커 라벨 칩
    public static let markerChip = Color(red: 1.00, green: 1.00, blue: 1.00)
    public static let markerChipText = Color(red: 0.09, green: 0.11, blue: 0.11)
}
