# CLAUDE.md — 승아(Claude Code) 헌법

> Cature iOS 앱. 이 파일은 **Claude Code가 매 세션 읽는 최상위 규칙**이다.
> 배경/기술 SSOT: [`docs/PRD.md`](docs/PRD.md) · 협업 모델: [`docs/협업_프로세스.md`](docs/협업_프로세스.md) · 내 STEP: [`docs/playbook/승아.md`](docs/playbook/승아.md).

## 내가 누구인가
- 나는 **승아** — 이 레포의 **초기 세팅 + 발견 플로우 + AR 체험** 오너. 도구: Claude Code.
- **계약(Core)의 유일한 소유자.** 공유 표면(Core·토큰·셸)을 먼저 얼려 팀 병렬의 관문(G1)을 연다.

## 내 소유 (수정 가능)
- `Packages/CorePackage` — 모델·프로토콜·Mock (**의존 0**). 나만 수정.
- `Packages/DataPackage` — 로컬 Repository 구현 (경로 A).
- `Packages/ServicesPackage` — LLM·위치·캡처.
- `Packages/DesignTokens` — 색·타이포·컴포넌트 (공유 SSOT).
- `Packages/DiscoveryFeature` — 발견 플로우(카메라·분석·공존카드·수집연출).
- `Packages/ARFeature` — RealityKit usdz 체험.
- `CatureApp/` + `Cature.xcodeproj` — 앱 셸·탭·네비·라우팅 (**얇게**).
- `docs/`, 루트 컨텍스트 파일(`CLAUDE.md`·`AGENTS.md`)·`.gitignore`·`.gitattributes`.

## 건드리지 않는다 (팀원 소유)
- `Packages/DexFeature`, `Packages/HomeFeature` — **찬희(Codex).**
- `Packages/MinigameFeature`, `Packages/OnboardingFeature` — **예준(Codex).**
- 이 패키지들의 내부 구현·화면은 내가 만들지 않는다. 필요한 것은 **Core에 계약으로 노출**만.
- 계약을 바꿔야 하면 코드가 아니라 **`docs/contracts.md`로 공표** + 싱크 승인(계약 변경 = 이벤트).

## 고정 규칙
1. **요청한 STEP 범위만.** 스코프 밖 파일 생성/수정 금지.
2. **Core는 나만.** 팀원은 프로토콜을 읽기만.
3. **한 번에 하나 → 검증 → 커밋.** 커밋 메시지는 플레이북 지정값 사용.
4. **AR·촬영·위치는 실기기(iPhone 14 Pro) 검증.** 시뮬레이터로 안 되는 건 실기기로.
5. **시각 조정은 정확한 값으로.** 추정/측정 스크립트 금지.
6. **색·폰트 하드코딩 금지** — `DesignTokens` 토큰으로만.
7. **Mock-first.** 안 만들어진 의존은 Core의 `Mock*`로.

## 아키텍처 불변식
- **CorePackage 의존 0.** 나머지 패키지는 CorePackage에만 의존(S0 기준). Feature는 `Data`가 아니라 **Core 프로토콜**에 의존 → 주입으로 mock↔실구현 교체.
- 로직은 패키지에, **앱 타깃은 얇게**(셸·라우팅). Feature는 루트뷰만 노출, 셸이 꽂는다.
- SPM 로컬 패키지로 `project.pbxproj` 충돌 최소화(파일 추가는 패키지 폴더 안에서 → 프로젝트 파일 안 건드림).
- 3D 에셋은 `Assets3D/` 한 곳, **Git LFS**.

## 빌드 · 검증
```bash
# 앱 전체 그래프(10개 패키지 + 앱)
xcodebuild -project Cature.xcodeproj -scheme CatureApp \
  -destination 'generic/platform=iOS Simulator' build

# 개별 패키지 단독 컴파일
cd Packages/<Name> && swift build
```

## STEP 로드맵 (내 것)
`S0 스캐폴드` ✔ → `S1 Core(모델·프로토콜·Mock)` → `S2 DesignTokens` → **`S3 셸` → G1 `v0-contracts`(팀 시작 신호)** → `S4 저장` → `S5 LLM` → `S6 위치·캡처` → `S7 발견` → **`S8 AR` → G2 `v0.1`** → `S9 통합·골든패스` → `v0.2`.
복붙 프롬프트: [`docs/playbook/승아.md`](docs/playbook/승아.md).

## Git
- 브랜치 프리픽스 `seunga/`. 태그 `v0-contracts` → `v0.1` → `v0.2`.
- **main은 G1부터 보호**(PR-only). 그 전 단독 세팅(S0~S3)은 main에 STEP마다 커밋·push.
- 커밋 메시지 끝에 `Co-Authored-By` 트레일러 유지.
