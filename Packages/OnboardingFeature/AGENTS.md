이 패키지 내부 파일만 작업한다.

- CorePackage, ServicesPackage, 다른 Feature, App 수정 금지.
- 데이터는 CorePackage 프로토콜과 Mocks로만 접근한다.
- 수집 종, 발견 위치, 현재 위치, 프로필 읽기는 CorePackage 프로토콜과 Mocks를 통해서만 한다.
- 스타일은 DesignTokens만 사용하고, 색/폰트/간격 하드코딩 금지.
- 완료 전 mock 주입으로 컴파일과 SwiftUI 프리뷰를 확인한다.
