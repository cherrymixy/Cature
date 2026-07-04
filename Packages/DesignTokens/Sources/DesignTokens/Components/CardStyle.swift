//  CardStyle.swift
//  DesignTokens — 라운드 카드 컴포넌트 (PRD §7). 홈=.light, 카메라 계열=.dark.

import SwiftUI

public struct CatureCardModifier: ViewModifier {
    let appearance: CatureAppearance

    public init(appearance: CatureAppearance) {
        self.appearance = appearance
    }

    public func body(content: Content) -> some View {
        content
            .padding(CatureSpacing.md)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: CatureRadius.card, style: .continuous))
            .shadow(color: .black.opacity(appearance == .light ? 0.08 : 0.40), radius: 12, x: 0, y: 4)
    }

    private var backgroundColor: Color {
        switch appearance {
        case .light: CatureColor.surface
        case .dark:  CatureColor.darkSurfaceElevated
        }
    }
}

public extension View {
    /// 라운드 카드 스타일. 공존카드·개체카드 등에 사용.
    func catureCard(_ appearance: CatureAppearance = .light) -> some View {
        modifier(CatureCardModifier(appearance: appearance))
    }
}
