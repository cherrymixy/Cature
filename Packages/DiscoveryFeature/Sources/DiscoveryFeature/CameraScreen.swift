//  CameraScreen.swift
//  DiscoveryFeature — 발견 카메라 화면(Figma 93-331): 라이브 프리뷰 + 힌트 + 셔터 + 뒤로.
//  라이브 프리뷰는 실기기 전용. 시뮬레이터/카메라 없음 → 셔터가 사진 보관함 폴백.

import SwiftUI
import AVFoundation
import DesignTokens

struct CameraScreen: View {
    let controller: CameraController
    let onCaptured: @Sendable (URL) -> Void   // 라이브 카메라 촬영 결과
    let onPickFallback: () -> Void     // 카메라 없을 때(시뮬) 피커 폴백
    let onClose: (() -> Void)?

    var body: some View {
        ZStack {
            Color(red: 0.055, green: 0.067, blue: 0.082).ignoresSafeArea()   // #0e1115
            #if canImport(UIKit)
            if controller.isCameraAvailable {
                CameraPreview(session: controller.session).ignoresSafeArea()
            }
            #endif
            overlay
        }
        .onAppear { if controller.isCameraAvailable { controller.start() } }
        .onDisappear { controller.stop() }
    }

    private var overlay: some View {
        VStack(spacing: 0) {
            HStack {
                if let onClose {
                    Button { onClose() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 3)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("닫기")
                }
                Spacer()
            }
            .padding(.horizontal, CatureSpacing.md)
            .padding(.top, CatureSpacing.xs)

            Spacer()

            Text(controller.isCameraAvailable ? "생물을 화면에 담아 보세요!" : "사진 보관함에서 골라 보세요")
                .font(.system(size: 16))
                .tracking(-0.8)
                .foregroundStyle(Color(red: 0.478, green: 0.478, blue: 0.478))   // #7a7a7a
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .background(Color.white.opacity(0.85), in: Capsule())
                .overlay(Capsule().stroke(.black.opacity(0.05)))
                .padding(.bottom, CatureSpacing.lg)

            Button { shutterTapped() } label: {
                ZStack {
                    Circle().stroke(.white, lineWidth: 4).frame(width: 70, height: 70)
                    Circle().fill(.white).frame(width: 58, height: 58)
                }
                .shadow(color: .black.opacity(0.25), radius: 6)
            }
            .accessibilityLabel("촬영")
            .padding(.bottom, 40)
        }
    }

    private func shutterTapped() {
        if controller.isCameraAvailable {
            controller.capturePhoto { [onCaptured] url in if let url { onCaptured(url) } }
        } else {
            onPickFallback()
        }
    }
}

#if canImport(UIKit)
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
#endif
