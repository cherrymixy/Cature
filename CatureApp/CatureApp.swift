//  CatureApp.swift
//  Cature — 앱 진입점 + 셸.
//
//  이 타깃은 "얇게" 유지한다: 셸·탭·네비·라우팅만.
//  기능 화면과 로직은 전부 Packages/의 Feature 패키지에 있다.
//  3탭(홈/기능/마이) + 카메라 FAB + 라우팅은 S3에서 조립한다(지금은 자리표시자).

import SwiftUI

@main
struct CatureApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

/// 앱 셸 자리표시자. S3에서 TabView(홈/기능/마이) + 카메라 FAB로 교체된다.
struct RootView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("Cature")
                    .font(.largeTitle.bold())
                Text("스캐폴드 골격 (S0)\n셸·탭·FAB는 S3")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

#Preview {
    RootView()
}
