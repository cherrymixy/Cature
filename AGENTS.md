# AGENTS.md — Cature 팀 공통 규칙

> 모든 에이전트/기여자가 읽는 **공통 규칙**이다. 특히 Codex는 작업 디렉터리에서 루트로 올라가며 `AGENTS.md`를 병합하고 **가까운 파일이 우선**한다 → 각자 자기 Feature 폴더의 `AGENTS.md`가 최우선 펜스.
> 승아(Claude Code)는 추가로 루트 [`CLAUDE.md`](CLAUDE.md)를 따른다.
> 제품 SSOT: [`docs/PRD.md`](docs/PRD.md) · 협업 모델: [`docs/협업_프로세스.md`](docs/협업_프로세스.md).

## 프로젝트 한 줄
카메라로 실제 생물 발견 → LLM 개체 분석 → 공존 카드 → 로컬 수집(도감·지도) → AR 체험.
SwiftUI + ARKit/RealityKit(usdz), 저장 로컬, 타깃 **iPhone 14 Pro(iOS 17+)**.

## 오너십 맵
| 오너 | 도구 | 소유 패키지 |
|---|---|---|
| **승아** | Claude Code | Core · Data · Services · DesignTokens · DiscoveryFeature · ARFeature · CatureApp(셸) |
| **찬희** | Codex | DexFeature · HomeFeature |
| **예준** | Codex | MinigameFeature · OnboardingFeature |

## 절대 규칙
1. **자기 패키지 밖 금지.** 다른 Feature·`CorePackage`·`DataPackage`·`ServicesPackage`·`CatureApp` 수정 금지. (프롬프트에도 매번 "내 패키지 밖 금지" 한 줄.)
2. **Core/Services는 승아만 수정.** 계약(모델·프로토콜)은 **읽기만**. 바꿔야 하면 승아에게 요청 → `docs/contracts.md` 갱신 = 이벤트.
3. **토큰은 `DesignTokens`만.** 색·폰트·간격·라운드 하드코딩 금지.
4. **Mock-first.** 실구현이 없으면 Core의 `Mock*`로 컴파일·실행(빈 화면이라도 돎).

## 패키지 펜스 (찬희·예준, 각자 S0)
- 각자 자기 Feature 폴더에 `AGENTS.md`를 만들어 박는다: *"이 패키지 안에서만 작업. 다른 Feature·Core 수정 금지. 토큰 참조. mock으로 컴파일 확인."*
  - 예: `Packages/DexFeature/AGENTS.md`(찬희), `Packages/MinigameFeature/AGENTS.md`(예준).
- Codex를 **해당 패키지 디렉터리에서 실행**하면 그 폴더 규칙이 최우선.
- `AGENTS.md`는 32KB에서 잘림 → 길면 패키지별로 쪼갠다.

## 아키텍처
- **`CorePackage` 의존 0**, Feature·Data·Services는 여기만 import(`DesignTokens`는 순수 디자인 레이어로 의존 0). Feature는 Core **프로토콜**에 의존(주입으로 mock↔실구현 교체). `Data`/`Services` 직접 의존 금지.
- 앱 타깃은 얇게(셸·라우팅). Feature는 **루트뷰만 노출**, 셸이 한 줄로 꽂는다.
- 계약 요약: `docs/contracts.md`(S1 생성 예정). 토큰 사용법: `docs/tokens.md`(S2 생성 예정).

## 빌드 · 검증
```bash
cd Packages/<MyFeature> && swift build   # 내 패키지 단독 컴파일
```
Xcode에서 `Cature.xcodeproj`를 열면 로컬 패키지가 자동 인식된다.

## GitHub / Xcode
- **main 보호(G1 `v0-contracts`부터): 직접 푸시 금지, PR로만.** PR = 작은 슬라이스(한 화면·한 규칙).
- 브랜치 프리픽스: `seunga/`, `chanhee/`, `yejun/`. 하루 이상 안 묵히고 자주 통합.
- 태그: `v0-contracts` → `v0.1` → `v0.2`.
- Core/계약을 건드리는 PR = **승아 필수 리뷰.** Feature 내부 = 오너 승인.
- usdz·대용량 에셋 = **Git LFS**(`Assets3D/`).

## 관문
- **G1 `v0-contracts`**(Core·Mock·토큰·셸) 초록 전엔 **병렬 시작 금지.**
