# Cature — 바이브코딩 PRD (빌드 SSOT)

> **Cature** = Capture + Nature/Creature. 카메라로 실제 생물을 발견 → LLM 개체 분석 → 공존 카드(필요 조건/방해 행동) → 도감·지도 수집 → AR 체험.
> 스택: **Swift + SwiftUI + ARKit/RealityKit (usdz)**, 저장 **로컬(경로 A)**, 배포 **iOS(iPhone 14 Pro)**.
> 이 문서는 **AI 코딩 에이전트가 읽는 기술 SSOT**다. 내러티브(요약·타겟·배경·문제·기능&범위·UX 플로우)는 `Cature 제품 요구 사항 정의서(PDF)` 참조.

---

## 0. 작업 방식 (하네스 + 도구 분업)

1. **계약 먼저 동결.** 모델·프로토콜(Repository/Service)·Mock·디자인 토큰·앱 셸을 승아가 먼저 얼린다(`v0-contracts`). 그 위에서 병렬.
2. **도구 분업.** 승아 = **Claude Code**(`CLAUDE.md`), 찬희·예준 = **Codex**(`AGENTS.md` + 패키지별 중첩). 스코프는 SPM 패키지 + 컨텍스트 파일로 이중 펜싱.
3. **콘텐츠 외부화.** 종 목록·LLM 프롬프트·공존 카드 캐시는 `data/`로.
4. **한 번에 하나 → 검증(스샷/실기기) → 커밋.** AR은 실기기 필수.
5. **로직은 Core만, Core는 승아만.** 팀원은 프로토콜을 **읽기만**.

---

## 1. 오너십 맵 & 저장소 구조

| 사람 | 도구 | 소유 모듈 |
|---|---|---|
| **승아** | Claude Code | 스캐폴드 · `CorePackage` · `DataPackage` · `ServicesPackage`(LLM·위치·캡처) · `DesignTokens` · `App`(셸) · **발견 플로우** · **AR 체험** |
| **찬희** | Codex | `DexFeature`(도감/마이) · `MinigameFeature`(카드 뒤집기→가위바위보) |
| **예준** | Codex | `HomeFeature`(지도) · `OnboardingFeature`(온보딩·Auth) |

```
Cature/
├─ CLAUDE.md               # 승아(Claude Code) 헌법
├─ AGENTS.md               # 루트 공통 규칙(Codex 공통)
├─ docs/{PRD.md, contracts.md, tokens.md, 협업_프로세스.md, 플레이북_*}
├─ Packages/
│  ├─ CorePackage/         # ★승아: Models + Protocols + Mocks (의존 0)
│  ├─ DataPackage/         # 승아: 로컬 Repository 구현
│  ├─ ServicesPackage/     # 승아: LLM·위치·캡처
│  ├─ DesignTokens/        # 승아: 색·타이포·컴포넌트 (공유)
│  ├─ DiscoveryFeature/    # 승아: 카메라·분석·공존카드·수집연출
│  ├─ ARFeature/           # 승아: RealityKit usdz 배치·체험
│  ├─ DexFeature/          # 찬희: 도감 + AGENTS.md(펜스)
│  ├─ HomeFeature/         # 예준: 홈 지도 + AGENTS.md
│  ├─ MinigameFeature/     # 찬희: 미니게임 + AGENTS.md
│  └─ OnboardingFeature/   # 예준: 온보딩·Auth + AGENTS.md
├─ Assets3D/               # 공용 usdz (Git LFS)
└─ App/                    # 승아: 셸·탭·네비(기능 루트뷰 조립)
```

- **CorePackage 의존 0**, 모두가 여기만 import. Feature는 `Data`가 아니라 `Core` 프로토콜에 의존 → 주입으로 mock↔실구현 교체.
- SPM 로컬 패키지 = `project.pbxproj` 충돌 제거 + 모듈 경계 컴파일러 강제(펜싱).

---

## 2. 데이터 모델 (Swift · Codable · CorePackage)

```swift
struct UserProfile: Codable { let userId: String; var nickname: String; var profileImagePath: String? }

struct Species: Codable {            // 도감 마스터 (data/로 외부화)
    let id: String; let nameKo: String; let category: String   // 파충류, 양서류, 곤충 …
    let usdzAsset: String?           // 없으면 체험 비활성
    let thumbnail: String?
}

struct CoexistCard: Codable {        // 종별 공존 카드 (캐시)
    let speciesId: String; let intro: String
    let needs: [String]              // 이 생명에게 필요한 조건
    let disturbances: [String]       // 사람이 방해할 수 있는 행동
    let source: CardSource           // curated | llm
}

struct AnalysisCandidate: Codable {  let speciesId: String?; let displayName: String; let confidence: Double }  // 0.0~1.0

struct Sighting: Codable {           // 저장된 발견 1건
    let id: String; let speciesId: String; let photoPath: String
    let latitude: Double?; let longitude: Double?; let locationName: String?
    let candidates: [AnalysisCandidate]; let createdAt: Date
}

struct CollectionEntry: Codable {    // 종별 수집 상태
    let speciesId: String; var captureCount: Int
    var discovered: Bool; var firstSeenAt: Date; var lastSeenAt: Date; var isFavorite: Bool
}
```

**프로토콜(계약, 승아 소유):** `SpeciesRepository`, `SightingRepository`, `CollectionRepository`, `ProfileRepository`, `LLMService`, `LocationService`, `CaptureService`. 각각 `Mock*` 제공.

---

## 3. 핵심 규칙 (동결 · MVP 기본값 확정)

1. **발견:** 촬영 → `LLMService.identify(image)` → 후보 배열(정확도 내림차순). 최고 정확도 임계 미만 → "다시 찍기" 강조.
2. **확정:** 사용자가 후보 1개 선택(자동 확정 아님).
3. **공존 카드:** 종 캐시 우선, 없으면 `LLMService.coexistCard(speciesId)` 생성 후 캐시.
4. **저장·수집:** 저장 시 `Sighting` 생성(사진 로컬 복사 + 좌표 + 시각), `CollectionEntry.captureCount += 1`, `discovered = true`.
5. **획득/달성률(기본값):** **저장 1회 = 도감 등재.** 촬영 횟수는 누적 표시. **달성률 = 발견 종수 ÷ 도감 대상 종수.** (촬영 N회=승격 방식은 후순위 옵션.)
6. **지도:** 발견 위치에 핀. **내가 수집한 것만**(로컬 확정).
7. **체험:** **수집(발견)한 종 + usdz 보유 종만** 체험. 없으면 비활성 안내.
8. **도감 세트(기본값):** **닫힌 큐레이션 세트**(usdz 보유 종). LLM은 그 외도 식별 시도하나, 도감 등재·체험은 큐레이션 종만. (종 수 N = usdz 확보량에 따라 확정 — §8.)
9. **가드레일:** 사람/무생물/판독 불가 → 낮은 confidence 또는 "생물을 찾지 못했어요". 사진·위치 로컬, LLM 전송 고지.
10. **테스트:** LLM·위치·시간 주입 가능(Mock·모의 좌표) → 경계 단위테스트.

---

## 4. 화면 & 오너

| 화면 | 오너 | 소비 계약 |
|---|---|---|
| 온보딩 / Auth | 예준 | `ProfileRepository` |
| 홈(지도) | 예준 | `CollectionRepository`·`SightingRepository`·`LocationService` (+ MapKit) |
| 카메라(발견/체험 토글) | 승아 | `CaptureService` (체험은 ARFeature로 라우팅) |
| 분석(후보·정확도) | 승아 | `LLMService` |
| 공존 카드 | 승아 | `LLMService`·`SpeciesRepository` |
| 수집 연출 | 승아 | `SightingRepository`·`CollectionRepository` |
| 마이(도감·달성률·종 상세) | 찬희 | `CollectionRepository`·`SpeciesRepository` |
| 미니게임(카드 뒤집기→가위바위보) | 찬희 | `CollectionRepository`(수집 종·usdz·썸네일 읽기) |
| 체험(AR) | 승아 | `CollectionRepository` + usdz |
| 앱 셸·탭·카메라 FAB | 승아 | (조립) |

---

## 5. LLM 분석 전략 (승아 · ServicesPackage)

- **종 식별(비전):** 이미지 → 멀티모달 → **후보 3개 + 정확도%**. 응답은 **엄격한 JSON**(후보 배열)으로 강제, 안전 파싱.
- **공존 카드 생성(텍스트):** 확정 종 → 소개 1줄 + 필요 2~3 + 방해 2~3. **종별 1회 생성 후 캐시.** 큐레이션 종은 검수 캐시 우선.
- **프롬프트 외부화:** `data/prompts/identify.txt`, `data/prompts/coexist.txt`.
- **정확도%:** 모델 confidence는 진짜 확률 아님 → "정보 정확도" 라벨로 표시, 과신 금지.
- **키:** 데모는 로컬 config(비커밋). 프로덕션은 프록시 권장.
- **Mock:** `MockLLMService`가 고정 후보(카멜레온 78/도마뱀 24/버섯 2)와 샘플 공존 카드 반환 → 팀원 즉시 개발.

---

## 6. 로컬 저장 (경로 A · 승아 · DataPackage)

- **상태**(코인성 없음): `UserDefaults`.
- **기록**(`Sighting`·`CollectionEntry`·`UserProfile`): `Codable` JSON 파일 또는 `SwiftData`.
- **사진**: picker/캡처 임시 파일 → documents 하위로 **복사** 후 경로 저장. 교체·삭제 시 옛 파일 정리.
- 전부 **Repository 프로토콜 뒤**에 구현 → 나중에 서버 필요 시 프로토콜 유지, 구현만 교체.

---

## 7. 디자인 토큰 방향 (승아 씨앗 · DesignTokens)

- **라이트:** 홈(지도) — 화이트/뉴트럴, 라운드 카드, 알약형 하단 탭, 다크 원형 카메라 FAB, 마커 라벨 칩.
- **다크:** 카메라·분석·공존카드·수집연출·체험 — 딥 그레이/블랙, 라운드 카드, 클린 산세리프(Pretendard 계열), **저폴리 usdz 캐릭터**가 주인공.
- 톤: "정복"이 아니라 "이해·배려". 획득 연출도 차분히.
- 토큰: `Color`, `Typography`, `Spacing`, `Radius`, `CardStyle`, `PillTabStyle` — 모든 Feature가 참조.

---

## 8. 열린 값 (빌드 중 확정)

| 항목 | 값 |
|---|---|
| 도감 대상 종 수 N | usdz 확보량 기준(데모 6~10종 권장) |
| usdz 에셋 소스 | 확보/제작 경로 정하기 (AR·도감·미니게임 공용) |
| 미니게임 | 카드 뒤집기(우선) → 가위바위보(여유) |
| 획득 승격 | 기본 1회 등재 (촬영 N회 승격은 옵션) |

---

## 한 줄 요약
**Cature = 발견(카메라+LLM) → 공존 카드 → 로컬 수집(도감·지도) → AR 체험. Core는 승아가 SPM으로 얼리고, 찬희(도감·미니게임)·예준(홈·온보딩)은 Codex로 자기 패키지에서 병렬. 저장은 로컬, 미니게임은 수집 종 재사용.**
