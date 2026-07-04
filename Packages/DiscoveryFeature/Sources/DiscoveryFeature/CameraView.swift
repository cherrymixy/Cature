//  CameraView.swift
//  DiscoveryFeature — 촬영 화면(토글 없음). 진입 시 카메라가 바로 뜨고,
//  취소/다시 찍기로 돌아오면 이 화면에서 촬영 버튼으로 재시도.

import SwiftUI
import DesignTokens

struct CameraView: View {
    let vm: DiscoveryViewModel
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

            Spacer()
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 72, weight: .thin))
                .foregroundStyle(CatureColor.darkTextSecondary)
            Text("생물을 화면에 담아 보세요")
                .font(CatureFont.body)
                .foregroundStyle(CatureColor.darkTextSecondary)
            Spacer()

            Button {
                Task { await vm.capture() }
            } label: {
                Circle()
                    .fill(.white)
                    .frame(width: 74, height: 74)
                    .overlay(Circle().stroke(CatureColor.darkSurface, lineWidth: 4).padding(4))
            }
            .accessibilityLabel("촬영")
        }
    }
}
