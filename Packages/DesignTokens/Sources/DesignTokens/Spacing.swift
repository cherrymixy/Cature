//  Spacing.swift
//  DesignTokens — 간격·라운드 토큰 (PRD §7, 라운드 카드).

import CoreGraphics

public enum CatureSpacing {
    public static let xxs: CGFloat = 4
    public static let xs:  CGFloat = 8
    public static let sm:  CGFloat = 12
    public static let md:  CGFloat = 16
    public static let lg:  CGFloat = 24
    public static let xl:  CGFloat = 32
    public static let xxl: CGFloat = 48
}

public enum CatureRadius {
    public static let sm:   CGFloat = 8
    public static let md:   CGFloat = 14
    public static let lg:   CGFloat = 20
    public static let card: CGFloat = 20    // 라운드 카드 기본
    public static let pill: CGFloat = 999   // 알약형 탭/캡슐
}
