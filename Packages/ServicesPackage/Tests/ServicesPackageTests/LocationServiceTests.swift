//  LocationServiceTests.swift
//  역지오코딩 이름 포맷(순수 함수) 검증. 실제 좌표/촬영은 실기기.

import Testing
@testable import ServicesPackage

@Suite("LocationService 이름 포맷")
struct LocationServiceTests {

    @Test("구/동 우선, 시 결합")
    func cityAndDistrict() {
        #expect(formatLocationName(locality: "서울특별시", administrativeArea: "서울특별시", subLocality: "중구", thoroughfare: "세종대로") == "서울특별시 중구")
    }

    @Test("subLocality 없으면 thoroughfare 폴백")
    func thoroughfareFallback() {
        #expect(formatLocationName(locality: "성남시", administrativeArea: "경기도", subLocality: nil, thoroughfare: "판교로") == "성남시 판교로")
    }

    @Test("locality 없으면 administrativeArea 폴백")
    func adminFallback() {
        #expect(formatLocationName(locality: nil, administrativeArea: "제주특별자치도", subLocality: "애월읍", thoroughfare: nil) == "제주특별자치도 애월읍")
    }

    @Test("전부 없으면 nil")
    func allNil() {
        #expect(formatLocationName(locality: nil, administrativeArea: nil, subLocality: nil, thoroughfare: nil) == nil)
    }
}
