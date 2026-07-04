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

### 2026-07-05 · 하단바 소유 이관 → 예준 (최종 디자인)
> ⚠️ 앞선 "하단바=셸 소유" 방향을 **정정**한다. 하단바 최종 디자인은 예준 것이 맞고, 셸의 현재 하단바는 임시다.
- **결정:** 앱 **하단바(내비 + 카메라 FAB)의 소유·최종 디자인 = 예준.** `AppShell`의 현재 하단바(홈/기능/마이 알약 + 발견·AR 스피드다이얼)는 **임시** → 예준 디자인으로 대체된다.
- **현황:** `HomeFeature.RootView`가 이미 자체 하단바(Home/checklist/person) + 카메라 FAB를 렌더 → 지금은 셸 임시 바와 **겹쳐 보임**(과도기). 예준 바 버튼은 아직 no-op.
- **예준 담당:** 하단바를 **앱 전역 컴포넌트**로 최종화 — 탭 전환(홈/기능/마이) + **발견/AR 진입 FAB** 동작 포함. 시각·구성은 예준.
- **승아(셸) 담당:** 라우팅 상태·콜백(`selectedTab`·`showCamera`·`showExperience`) 주입 제공. 예준 하단바 확정되면 셸의 **임시 하단바 제거** + 예준 컴포넌트에 콜백 연결.
- **부수(예준 확인):** 홈 타이틀 "Cature"가 좌측에서 잘려 **"ature"**로 보임 — `titleSection` 좌측 오프셋/패딩 점검 부탁.

### 2026-07-05 · 하단바 → Figma 133-483 최종 디자인 적용 (승아, 셸)
> 위 이관 논의 후속. 사용자 지시로 **셸이 Figma 133-483 하단바를 최종 디자인으로 구현**.
- **적용:** `AppShell` 하단바 = **회색 프로스트 알약**(gradient rgba(211~233,.6)+blur, 선택 탭 = 흰 전체높이 알약 아이콘+라벨, 비선택 = 아이콘만) + **로고 FAB**(`Image("logo")` = `CatureApp/Assets.xcassets/logo.imageset`, 원본 `Assets3D/logo.svg`). `DesignTokens.CatureColor.fab` = #0d0f18.
- **탭:** Home(house.fill)·Task(list.bullet.rectangle.fill)·My(person.fill), **영어 라벨**(Figma 그대로). 컨테이너는 넓게(가용 폭 채움, 우측 여백). FAB는 발견/AR 스피드다이얼 유지.
- **예준 요청:** 전역 하단바는 이제 셸이 133-483로 담당하므로, `HomeFeature.RootView`의 **자체 하단바(`bottomBar`)는 제거** 부탁. 지금은 셸 바가 위를 덮어 가려지지만 중복.
