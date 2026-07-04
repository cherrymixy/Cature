//  Typography.swift
//  DesignTokens — 타이포 토큰 (PRD §7). Pretendard 계열 대체 = 시스템 산세리프.
//
//  나중에 Pretendard를 붙일 때 이 파일 한 곳만 바꾸면 전 화면 반영.

import SwiftUI

public enum CatureFont {
    public static let largeTitle = Font.system(size: 34, weight: .bold)
    public static let title      = Font.system(size: 24, weight: .bold)
    public static let headline   = Font.system(size: 18, weight: .semibold)
    public static let body       = Font.system(size: 16, weight: .regular)
    public static let callout    = Font.system(size: 15, weight: .regular)
    public static let caption    = Font.system(size: 13, weight: .regular)
}
