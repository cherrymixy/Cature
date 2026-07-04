//  CameraController.swift
//  DiscoveryFeature — 커스텀 라이브 카메라(AVFoundation). 발견 화면의 프리뷰 + 셔터 촬영.
//  실기기 전용 동작(시뮬레이터는 카메라 없음 → CameraScreen이 피커 폴백).

import AVFoundation
import Foundation

final class CameraController: NSObject, @unchecked Sendable {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let queue = DispatchQueue(label: "cature.camera.session")
    private var onCaptured: (@Sendable (URL?) -> Void)?

    /// 이 기기에 카메라가 있는가(시뮬레이터=false).
    var isCameraAvailable: Bool {
        AVCaptureDevice.default(for: .video) != nil
    }

    func start() {
        queue.async { [self] in
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                beginSession()
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    guard granted else { return }
                    self.queue.async { self.beginSession() }
                }
            default:
                break   // 거부/제한 → 프리뷰 없음
            }
        }
    }

    func stop() {
        queue.async { [self] in
            if session.isRunning { session.stopRunning() }
        }
    }

    private func beginSession() {
        if session.inputs.isEmpty {
            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device) else { return }
            session.beginConfiguration()
            session.sessionPreset = .photo
            if session.canAddInput(input) { session.addInput(input) }
            if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }
            session.commitConfiguration()
        }
        if !session.inputs.isEmpty, !session.isRunning {
            session.startRunning()
        }
    }

    /// 셔터: 사진 촬영 → 임시 JPEG URL(메인 스레드 콜백).
    func capturePhoto(_ completion: @escaping @Sendable (URL?) -> Void) {
        queue.async { [self] in
            guard session.isRunning else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            onCaptured = completion
            photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        }
    }
}

extension CameraController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let url: URL? = photo.fileDataRepresentation().flatMap { data in
            let dest = FileManager.default.temporaryDirectory
                .appendingPathComponent("capture-\(UUID().uuidString).jpg")
            return (try? data.write(to: dest)) != nil ? dest : nil
        }
        let callback = onCaptured
        onCaptured = nil
        DispatchQueue.main.async { callback?(url) }
    }
}
