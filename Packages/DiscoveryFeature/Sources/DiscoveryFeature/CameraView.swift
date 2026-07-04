//  CameraView.swift
//  DiscoveryFeature — 카메라 진입(발견/체험 토글 + 촬영). 체험은 ARFeature로 라우팅만.

import SwiftUI
import DesignTokens

struct CameraView: View {
    @Bindable var vm: DiscoveryViewModel
    let onEnterExperience: () -> Void
    let onClose: (() -> Void)?

    var body: some View {
        VStack(spacing: CatureSpacing.lg) {
            HStack {
                if let onClose {
                    Button { onClose() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(CatureColor.darkTextPrimary)
                    }
                    .accessibilityLabel("닫기")
                }
                Spacer()
            }

            Picker("mode", selection: $vm.mode) {
                Text("발견").tag(DiscoveryMode.discover)
                Text("체험").tag(DiscoveryMode.experience)
            }
            .pickerStyle(.segmented)

            Spacer()
            Image(systemName: vm.mode == .discover ? "camera.viewfinder" : "cube.transparent")
                .font(.system(size: 72, weight: .thin))
                .foregroundStyle(CatureColor.darkTextSecondary)
            Text(vm.mode == .discover ? "생물을 화면에 담아 보세요" : "수집한 종을 AR로 만나요")
                .font(CatureFont.body)
                .foregroundStyle(CatureColor.darkTextSecondary)
            Spacer()

            if vm.mode == .discover {
                Button {
                    Task { await vm.capture() }
                } label: {
                    Circle()
                        .fill(.white)
                        .frame(width: 74, height: 74)
                        .overlay(Circle().stroke(CatureColor.darkSurface, lineWidth: 4).padding(4))
                }
                .accessibilityLabel("촬영")
            } else {
                Button("체험 시작") { onEnterExperience() }
                    .buttonStyle(.caturePrimary)
            }
        }
    }
}
