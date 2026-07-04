# Cature — 계약 (contracts) · 팀원용 SSOT

> `CorePackage`가 노출하는 **모델·프로토콜·Mock** 요약. 찬희·예준은 이 표를 읽고 Feature를 만든다.
> ⚠️ **이 계약은 승아 소유.** 바꿔야 하면 승아에게 요청 → 여기 갱신 = 이벤트(싱크 공표·승인). 몰래 바꾸지 않기.
> 실체 정의: `Packages/CorePackage/Sources/CorePackage/{Models,Protocols,CollectionMath}.swift`. 전부 `public`, 값 타입은 `Codable`·`Hashable`·`Sendable`.

## 1. 데이터 모델 (PRD §2)

| 타입 | 주요 필드 | 비고 |
|---|---|---|
| `UserProfile` | `userId`, `nickname`, `profileImagePath?` | `Identifiable`(id=userId) |
| `Species` | `id`, `nameKo`, `category`, `usdzAsset?`, `thumbnail?` | 도감 마스터. `canExperience`=usdz 보유 여부 |
| `CoexistCard` | `speciesId`, `intro`, `needs[]`, `disturbances[]`, `source` | `source`: `.curated` \| `.llm` |
| `AnalysisCandidate` | `speciesId?`, `displayName`, `confidence(0~1)`, `category?` | 큐레이션 아니면 `speciesId=nil`. confidence=정보 정확도. category=동물·식물 등 분석 라벨(#21) |
| `Sighting` | `id`, `speciesId`, `photoPath`, `latitude?`, `longitude?`, `locationName?`, `candidates[]`, `createdAt` | 발견 1건 |
| `CollectionEntry` | `speciesId`, `captureCount`, `discovered`, `firstSeenAt`, `lastSeenAt`, `isFavorite` | 종별 수집 상태 |
| `CardSource` | `.curated` / `.llm` | enum |
| `LocationSample` | `latitude`, `longitude`, `locationName?` | LocationService 반환형 |

## 2. 프로토콜 (계약)

| 프로토콜 | 메서드 | 소비 화면(오너) |
|---|---|---|
| `SpeciesRepository` | `allSpecies()` · `species(id:)` | 도감·상세(찬희), 발견(승아) |
| `SightingRepository` | `allSightings()` · `sightings(speciesId:)` · `save(_:)` | 홈 지도(예준), 발견(승아) |
| `CollectionRepository` | `allEntries()` · `entry(speciesId:)` · `recordCapture(speciesId:at:)` · `setFavorite(speciesId:_:)` | 도감·달성률(찬희), 미니게임(찬희), 수집연출(승아) |
| `ProfileRepository` | `load()` · `save(_:)` | 온보딩·Auth(예준) |
| `LLMService` | `identify(image:)` · `coexistCard(speciesId:)` | 분석·공존카드(승아) |
| `LocationService` | `currentLocation()` | 홈(예준), 발견(승아) |
| `CaptureService` | `capturePhoto()` | 카메라(승아) |

> 저장소/서비스 메서드는 **모두 `async`**(위치는 `async`, 나머지 `async throws`). 프로토콜은 `Sendable` → Task/actor 경계로 안전히 주입.

## 3. 얼린 규칙 (구현·테스트로 고정)

- **저장 규칙(§3.4):** `recordCapture` = `captureCount += 1`, `discovered = true`, `lastSeenAt = date`, 첫 발견이면 `firstSeenAt = date`.
- **달성률(§3.5):** `CollectionMath.achievement(discoveredCount:totalSpecies:)` = 발견 종수 ÷ 도감 대상 종수 (0…1). **저장 1회 = 도감 등재.**
- **체험 조건(§3.7):** `Species.canExperience`(usdz 보유) + 수집(발견)한 종만.
- **식별(§3.1):** 후보는 confidence **내림차순**. 최고 정확도 임계 미만 → "다시 찍기".

## 4. Mock (mock-first, `CorePackage/Mocks`)

| Mock | 동작 |
|---|---|
| `MockLLMService` | `identify` → **카멜레온 0.78 / 도마뱀 0.24 / 버섯 0.02** 고정. `coexistCard("chameleon")` → 검수 카드, 그 외 → 폴백(`.llm`) |
| `MockSpeciesRepository` | `SampleData.species` 4종 시드(카멜레온·도마뱀·청개구리·무당벌레). 무당벌레는 usdz 없음(체험 비활성) |
| `MockSightingRepository` | 메모리 배열 |
| `MockCollectionRepository` | 메모리 dict, 저장 규칙 구현 |
| `MockProfileRepository` | 메모리 1건 |
| `MockLocationService` | 서울 좌표 고정(`sample: nil`로 거부 시뮬레이션) |
| `MockCaptureService` | 빈 임시 파일 URL 반환 |

**주입 예 (Feature에서):**
```swift
import CorePackage
let species: any SpeciesRepository = MockSpeciesRepository()
let candidates = try await MockLLMService().identify(image: imageData)  // [카멜레온, 도마뱀, 버섯]
```

## 5. 사용법
```bash
cd Packages/CorePackage && swift test    # 계약 경계 테스트
```
`import CorePackage` 한 줄로 모델·프로토콜·Mock 전부 사용. **Data/Services 구현에 직접 의존하지 말 것** — 프로토콜만.

## 6. 조율 이벤트 로그

### 2026-07-05 · 셸 ↔ HomeFeature 하단 내비 경계 (승아 → 예준)
- **상황:** `HomeFeature.RootView`가 **자체 하단바**(Home/checklist/person) + **카메라 FAB**를 렌더 → 셸 하단바(홈/기능/마이 알약 + 발견·AR 스피드다이얼 FAB)와 **겹침**.
- **규칙:** 하단 내비 + FAB는 **셸(승아) 소유**. Feature 루트뷰는 **콘텐츠만** 노출한다(홈 = 지도·타이틀·필터레일·카드). `AppShell`이 하단바를 얹는다. (근거: `CLAUDE.md` "Feature는 루트뷰만 노출, 셸이 꽂는다".)
- **요청(예준):** `HomeFeature/Sources/HomeFeature/RootView.swift`의 `bottomBar`(≈L106) + 그 안 자체 FAB **제거**. 탭 전환·발견·AR 진입은 셸이 처리하므로 Feature에 하단 내비 불필요.
- **상태:** 셸 배선 완료(#25, 홈 표시 정상). HomeFeature에서 하단바만 빼면 겹침 해소.
- **부수(예준 확인):** 홈 타이틀 "Cature"가 좌측에서 잘려 **"ature"**로 보임 — `titleSection` 좌측 오프셋/패딩 점검 부탁.
