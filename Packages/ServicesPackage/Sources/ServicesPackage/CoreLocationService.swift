//  CoreLocationService.swift
//  ServicesPackage — Core LocationService의 CoreLocation 구현 (PRD §6).
//  좌표 + 역지오코딩(구/동명). 권한 거부/불가 시 nil(좌표 없이 진행).
//  CLAuthorizationStatus.authorizedWhenInUse가 iOS 전용이라 서비스는 #if os(iOS).
//  이름 포맷(formatLocationName)은 순수 함수 → 크로스플랫폼(호스트 테스트용).

import Foundation
import CorePackage

#if os(iOS)
import CoreLocation

public final class CoreLocationService: NSObject, LocationService, CLLocationManagerDelegate, @unchecked Sendable {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var authContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?

    public override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    public func currentLocation() async -> LocationSample? {
        let status = await currentAuthorization()
        guard status == .authorizedWhenInUse || status == .authorizedAlways else { return nil }
        guard let location = await oneShotLocation() else { return nil }
        let name = await reverseGeocode(location)
        return LocationSample(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            locationName: name
        )
    }

    // MARK: 권한

    private func currentAuthorization() async -> CLAuthorizationStatus {
        let status = manager.authorizationStatus
        guard status == .notDetermined else { return status }
        return await withCheckedContinuation { continuation in
            authContinuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authContinuation?.resume(returning: manager.authorizationStatus)
        authContinuation = nil
    }

    // MARK: 위치(one-shot)

    private func oneShotLocation() async -> CLLocation? {
        await withCheckedContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationContinuation?.resume(returning: locations.last)
        locationContinuation = nil
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(returning: nil)
        locationContinuation = nil
    }

    // MARK: 역지오코딩

    private func reverseGeocode(_ location: CLLocation) async -> String? {
        let placemarks = try? await geocoder.reverseGeocodeLocation(location, preferredLocale: Locale(identifier: "ko_KR"))
        guard let placemark = placemarks?.first else { return nil }
        return formatLocationName(
            locality: placemark.locality,
            administrativeArea: placemark.administrativeArea,
            subLocality: placemark.subLocality,
            thoroughfare: placemark.thoroughfare
        )
    }
}
#endif

/// CLPlacemark 구성요소 → "시 구/동" 표기(구/동명). 순수 함수 → 단위테스트.
func formatLocationName(locality: String?, administrativeArea: String?, subLocality: String?, thoroughfare: String?) -> String? {
    let city = locality ?? administrativeArea
    let district = subLocality ?? thoroughfare
    let parts = [city, district].compactMap { $0 }.filter { !$0.isEmpty }
    return parts.isEmpty ? nil : parts.joined(separator: " ")
}
