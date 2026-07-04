//  PillTabStyle.swift
//  DesignTokens — 알약형 하단 탭 컨테이너 스타일 (PRD §7). S3 셸의 탭 바에 적용.

import SwiftUI

public struct CaturePillTabModifier: ViewModifier {
    let appearance: CatureAppearance

    public init(appearance: CatureAppearance) {
        self.appearance = appearance
    }

    public func body(content: Content) -> some View {
        content
            .padding(.horizontal, CatureSpacing.md)
            .padding(.vertical, CatureSpacing.sm)
            .background(appearance == .light ? CatureColor.surface : CatureColor.darkSurfaceElevated)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(appearance == .light ? 0.12 : 0.50), radius: 16, x: 0, y: 6)
    }
}

public extension View {
    /// 알약형 탭 바 컨테이너.
    func caturePillTab(_ appearance: CatureAppearance = .light) -> some View {
        modifier(CaturePillTabModifier(appearance: appearance))
    }
}
