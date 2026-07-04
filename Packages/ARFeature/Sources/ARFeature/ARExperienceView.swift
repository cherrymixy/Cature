//  ARExperienceView.swift
//  ARFeature — RealityKit AR 배치(평면 인식 → usdz 엔티티 + 제스처). iOS 전용.
//  실기기에서만 세션 동작(시뮬레이터=unsupported). 실기기(iPhone 14 Pro) 검증.

#if os(iOS)
import SwiftUI
import ARKit
import RealityKit

enum ARPlacementStatus: Equatable {
    case unsupported     // AR 미지원(시뮬레이터 등)
    case findingPlane    // 평면 찾는 중
    case readyToPlace    // 평면 찾음, 탭해서 배치
    case placed          // 배치됨
    case assetMissing    // usdz 로드 실패(에셋 없음)
}

struct ARExperienceView: UIViewRepresentable {
    let usdzAsset: String
    @Binding var status: ARPlacementStatus
    @Binding var lowLight: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(usdzAsset: usdzAsset, status: $status, lowLight: $lowLight)
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        context.coordinator.arView = arView

        guard ARWorldTrackingConfiguration.isSupported else {
            Task { @MainActor in status = .unsupported }
            return arView
        }

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        arView.session.delegate = context.coordinator
        arView.session.run(config)

        let coaching = ARCoachingOverlayView()
        coaching.session = arView.session
        coaching.goal = .horizontalPlane
        coaching.delegate = context.coordinator
        coaching.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coaching.frame = arView.bounds
        arView.addSubview(coaching)

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.delegate = context.coordinator
        arView.addGestureRecognizer(tap)

        Task { @MainActor in status = .findingPlane }
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    @MainActor
    final class Coordinator: NSObject, ARCoachingOverlayViewDelegate, ARSessionDelegate, UIGestureRecognizerDelegate {
        weak var arView: ARView?
        let usdzAsset: String
        @Binding var status: ARPlacementStatus
        @Binding var lowLight: Bool
        private var placed = false

        init(usdzAsset: String, status: Binding<ARPlacementStatus>, lowLight: Binding<Bool>) {
            self.usdzAsset = usdzAsset
            self._status = status
            self._lowLight = lowLight
        }

        // 오버레이(뒤로/종 선택 등) 위 탭은 배치 제스처가 가로채지 않게 → 버튼이 받도록.
        nonisolated func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard let gestureView = gestureRecognizer.view else { return true }
            return touch.view?.isDescendant(of: gestureView) ?? false
        }

        nonisolated func coachingOverlayViewDidDeactivate(_ overlayView: ARCoachingOverlayView) {
            Task { @MainActor in
                if !self.placed { self.status = .readyToPlace }
            }
        }

        // 조명 추정: ARFrame은 Sendable이 아니므로 nonisolated에서 Double만 뽑아 MainActor로.
        nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
            let ambient = frame.lightEstimate?.ambientIntensity ?? 1000
            Task { @MainActor in self.lowLight = ambient < 100 }
        }

        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let arView, !placed else { return }
            let point = sender.location(in: arView)
            guard let result = arView.raycast(from: point, allowing: .estimatedPlane, alignment: .horizontal).first else {
                return
            }
            do {
                let model = try ModelEntity.loadModel(named: usdzAsset)
                model.generateCollisionShapes(recursive: true)
                let anchor = AnchorEntity(world: result.worldTransform)
                anchor.addChild(model)
                arView.scene.addAnchor(anchor)
                arView.installGestures([.translation, .rotation, .scale], for: model)
                placed = true
                status = .placed
            } catch {
                status = .assetMissing   // usdz 없음/로드 실패 → graceful 안내
            }
        }
    }
}
#endif
