# Cature — 디자인 토큰 사용법

> `DesignTokens` 패키지가 노출하는 색·타이포·간격·컴포넌트. **색/폰트/간격 하드코딩 금지 — 토큰으로만.**
> 값은 임시(디자인 확정 전)지만 접근 방식은 고정. 값이 바뀌어도 사용처는 그대로.
> 실체: `Packages/DesignTokens/Sources/DesignTokens/`.

## 컨텍스트
Cature는 화면 톤을 둘로 나눈다 (PRD §7):
- `.light` — **홈·지도** (화이트/뉴트럴)
- `.dark` — **카메라·분석·공존카드·수집연출·체험** (딥그레이/블랙)

카드/탭 등 컴포넌트에 `CatureAppearance`로 넘긴다.

## 토큰
| 종류 | 접근 | 예 |
|---|---|---|
| 색 | `CatureColor.*` | `.accent`, `.surface`, `.textPrimary`, `.darkSurface`, `.fab`, `.markerChip` |
| 타이포 | `CatureFont.*` | `.largeTitle` `.title` `.headline` `.body` `.callout` `.caption` |
| 간격 | `CatureSpacing.*` | `.xxs`(4) `.xs`(8) `.sm`(12) `.md`(16) `.lg`(24) `.xl`(32) `.xxl`(48) |
| 라운드 | `CatureRadius.*` | `.card`(20) `.md`(14) `.pill` |

## 컴포넌트
```swift
import DesignTokens

// 라운드 카드
VStack { … }.catureCard(.light)     // 홈
VStack { … }.catureCard(.dark)      // 공존 카드

// 알약형 하단 탭 컨테이너 (S3 셸)
HStack { … }.caturePillTab(.light)

// 기본 버튼 (accent)
Button("저장하기") { … }.buttonStyle(.caturePrimary)

// 텍스트/색
Text("카멜레온")
    .font(CatureFont.headline)
    .foregroundStyle(CatureColor.textPrimary)
```

## 확인
`DesignTokens/Sources/DesignTokens/Previews.swift`의 `#Preview "Cature 디자인 토큰"`을 Xcode 캔버스에서 열면 타이포 스케일·카드·버튼·알약탭이 한 화면에.

## Pretendard
지금은 시스템 산세리프 대체. 실제 Pretendard 적용 시 `Typography.swift` 한 곳만 수정하면 전 화면 반영.
