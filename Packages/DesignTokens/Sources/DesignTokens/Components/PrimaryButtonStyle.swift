//  PrimaryButtonStyle.swift
//  DesignTokens — 기본 버튼 스타일 (accent). '저장하기' 등 주요 액션.

import SwiftUI

public struct PrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(CatureFont.headline)
            .foregroundStyle(CatureColor.onFab)
            .frame(maxWidth: .infinity)
            .padding(.vertical, CatureSpacing.sm)
            .background(CatureColor.accent)
            .clipShape(RoundedRectangle(cornerRadius: CatureRadius.md, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == PrimaryButtonStyle {
    /// `.buttonStyle(.caturePrimary)`
    static var caturePrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}
