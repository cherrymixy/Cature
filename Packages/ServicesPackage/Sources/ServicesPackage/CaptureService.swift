//  CaptureService.swift
//  ServicesPackage — Core CaptureService 구현 (PRD §6).
//  카메라 촬영(UIImagePickerController) + 사진 보관함 폴백(PHPicker). 임시 파일 URL 반환.
//  UIKit 전용 → macOS 호스트 빌드에서는 제외(#if canImport(UIKit)).

#if canImport(UIKit)
import UIKit
import PhotosUI
import CorePackage

public enum CaptureSource: Sendable {
    case camera
    case photoLibrary
    case automatic   // 카메라 가능하면 카메라, 아니면 사진 보관함
}

@MainActor
public final class ImagePickerCaptureService: NSObject, CaptureService {
    public struct Cancelled: Error {}

    private let source: CaptureSource
    private var continuation: CheckedContinuation<URL, Error>?

    public init(source: CaptureSource = .automatic) {
        self.source = source
        super.init()
    }

    public func capturePhoto() async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            present()
        }
    }

    private var resolvedSource: CaptureSource {
        guard source == .automatic else { return source }
        return UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
    }

    private func present() {
        guard let presenter = Self.topViewController() else {
            finish(.failure(Cancelled()))
            return
        }
        switch resolvedSource {
        case .camera:
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            presenter.present(picker, animated: true)
        case .photoLibrary, .automatic:
            var config = PHPickerConfiguration()
            config.filter = .images
            config.selectionLimit = 1
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            presenter.present(picker, animated: true)
        }
    }

    private func finish(_ result: Result<URL, Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }

    /// nonisolated: 어떤 스레드에서든 이미지 → 임시 JPEG 파일(URL은 Sendable)로.
    nonisolated static func writeTempJPEG(_ image: UIImage) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("capture-\(UUID().uuidString).jpg")
        return (try? data.write(to: url)) != nil ? url : nil
    }

    private static func topViewController() -> UIViewController? {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
        var top = keyWindow?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}

extension ImagePickerCaptureService: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage, let url = Self.writeTempJPEG(image) else {
            finish(.failure(Cancelled())); return
        }
        finish(.success(url))
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        finish(.failure(Cancelled()))
    }
}

extension ImagePickerCaptureService: PHPickerViewControllerDelegate {
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
            finish(.failure(Cancelled())); return
        }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            // nonisolated 컨텍스트에서 URL(Sendable)까지 만든 뒤 MainActor로 넘긴다.
            let url = (object as? UIImage).flatMap(ImagePickerCaptureService.writeTempJPEG)
            Task { @MainActor in
                guard let self else { return }
                self.finish(url.map { .success($0) } ?? .failure(Cancelled()))
            }
        }
    }
}
#endif
