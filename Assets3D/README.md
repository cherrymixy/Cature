# Assets3D — 공용 3D 에셋 (Git LFS)

Cature의 usdz 캐릭터/오브젝트를 **한 곳**에 둔다. AR 체험(`ARFeature`)·도감·미니게임이 공용으로 로드한다.

- 대상 확장자(`.usdz` · `.usdc` · `.usda` · `.reality`)는 **Git LFS**로 추적된다 (`../.gitattributes`).
- ⚠️ 에셋을 추가하기 **전에 한 번만**:
  ```bash
  brew install git-lfs
  git lfs install
  ```
  (LFS 미설치 상태로 usdz를 `git add` 하면 실패한다.)
- 원칙: 종별 **저폴리 usdz**. 에셋 소스/제작 경로는 PRD §8에서 확정.
