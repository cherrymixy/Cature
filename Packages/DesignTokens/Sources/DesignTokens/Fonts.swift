//  Fonts.swift
//  DesignTokens — 번들 폰트 런타임 등록.
//
//  SPM 리소스로 넣은 폰트는 앱 Info.plist(UIAppFonts)가 아니라 코드로 등록해야 한다.
//  Josefin Sans(브랜드 워드마크·영문 타이틀)만 실폰트. 본문 Pretendard는 .woff2(iOS 미지원)라
//  실 .otf/.ttf가 들어오기 전까지 시스템 산세리프로 폴백(Typography 참고).

import CoreText
import Foundation

public enum CatureFonts {
    /// 번들 폰트를 프로세스에 한 번만 등록. CatureFont.wordmark 접근 시 자동 호출된다.
    public static func registerIfNeeded() {
        _ = registerOnce
    }

    private static let registerOnce: Void = {
        register(resource: "JosefinSans-SemiBold", withExtension: "ttf")
    }()

    private static func register(resource: String, withExtension ext: String) {
        guard let url = Bundle.module.url(forResource: resource, withExtension: ext) else { return }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
}
