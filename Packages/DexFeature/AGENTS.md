이 패키지 내부 파일만 작업한다.

- CorePackage, ServicesPackage, 다른 Feature, App은 수정 금지.
- 데이터는 CorePackage 프로토콜과 Mocks로만 접근한다.
- 수집 종, usdz, 썸네일, 프로필 읽기는 주입된 프로토콜을 사용한다.
- 스타일은 DesignTokens만 사용하고 하드코딩하지 않는다.
- 완료 전 mock 주입으로 컴파일과 SwiftUI 프리뷰를 확인한다.
