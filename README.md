# Cature

카메라로 실제 생물을 발견 → LLM 개체 분석(필요 조건 / 방해 행동) → 도감·지도 수집 → AR 체험.
iOS 네이티브(SwiftUI + ARKit/RealityKit, usdz), 로컬 저장.

## 문서 인덱스
- [`docs/PRD.md`](docs/PRD.md) — 바이브코딩 PRD (빌드 SSOT)
- [`docs/협업_프로세스.md`](docs/협업_프로세스.md) — 3인 협업 모델·도구 분업
- [`docs/playbook/00_통합.md`](docs/playbook/00_통합.md) — 빌드 플레이북 통합본(관문·타임라인)
- [`docs/playbook/승아.md`](docs/playbook/승아.md) — 승아(Claude Code): 세팅+발견+AR
- [`docs/playbook/찬희.md`](docs/playbook/찬희.md) — 찬희(Codex): 도감+홈
- [`docs/playbook/예준.md`](docs/playbook/예준.md) — 예준(Codex): 미니게임+온보딩

## 빌드하면서 생성되는 파일 (지금 없음)
- 루트 `CLAUDE.md`, `AGENTS.md` — 승아 S0
- `docs/contracts.md` — 승아 S1 / `docs/tokens.md` — 승아 S2
- `Packages/*/AGENTS.md` — 찬희·예준 S0 (Codex 펜스)

## 시작
승아가 `docs/playbook/승아.md`의 S0부터. **S3 끝 = `v0-contracts` 태그**가 찬희·예준 병렬의 방아쇠.
