//  CatureApp.swift
//  Cature — 앱 진입점.
//
//  이 타깃은 얇게: 셸·탭·네비·라우팅만. 기능 화면/로직은 Packages/의 Feature 패키지에 있다.
//  (S9) 최초 실행 시 OnboardingFeature.RootView 게이트를 여기서 분기하게 된다.

import SwiftUI

@main
struct CatureApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
