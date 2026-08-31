# 변경 이력 (Changelog)

이 프로젝트의 모든 주요 변경 사항은 이 문서에 기록됩니다.

형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/)를 따르며,
이 프로젝트는 [Semantic Versioning (유의적 버전 2.0.0)](https://semver.org/lang/ko/)을 준수합니다.

## [Unreleased]

## [0.1.1] - 2026-08-31

### 추가 (Added)
- `SKILL.md`: 실제 Codex Native Subagent 생성을 위한 Downshift Spawn Contract 명시 (`model = "gpt-5.6-luna"`, `fork_turns = "none"`, `reasoning_effort`, `task_name`).
- `SKILL.md`: Luna spawn 실패 시 상위 모델로의 대체나 escalation 없이 부모 모델이 직접 수행하는 Fallback Invariant (불변 규칙) 추가.
- `SKILL.md`: Luna 작업 완료 후 부모 모델의 중복 작업 및 동일 테스트 재실행 방지 지침 추가.
- `references/delegation-examples.md`: 8대 핵심 검증 시나리오 매트릭스 및 실전 예시집 전면 보강.

### 변경 (Changed)
- `SKILL.md`: YAML Frontmatter `description`을 암시적 호출 판단에 맞추어 Sol/Terra 대상 및 비활성 조건 명확화.
- `task-capsule-template.md`: 부모 CoT/대화 제외 및 최소 컨텍스트 기반 토큰 효율 작성 원칙 반영.
- `README.md` & `docs/`: 설치 경로 정책 분리 (글로벌은 타 에이전트 오인식 방지를 위한 `~/.codex/skills/`, 프로젝트는 `.agents/skills/`).
- `README.md` & `SKILL.md`: "Luna 등" 모호한 표현을 `Luna` (`gpt-5.6-luna`) 단일 모델로 정돈하고, 과장된 성능 표현 완화 및 Leaf Worker 지침 레벨 제약 성격 명문화.

## [0.1.0] - 2026-08-31

### 추가 (Added)
- `codex-downshift` 초기 프로젝트 구조 구성.
- `skills/codex-downshift/SKILL.md`: Sol/Terra 부모 모델에서 확정된 실행 작업을 경량 리프 워커(Luna 등)로 다운시프트(위임)하는 핵심 프롬프트 스킬.
- `skills/codex-downshift/references/delegation-examples.md`: 실제 위임 시 모범 사례(Good) 및 안티패턴(Bad) 예시집.
- `skills/codex-downshift/references/task-capsule-template.md`: 한정된 작업 위임을 위한 Self-Contained 프롬프트 캡슐 표준 서식.
- `README.md`, `CONTRIBUTING.md`, `.gitignore` 등 기본 개발 환경 및 문서 구축.
- 원본 기획 문서를 `docs/codex-downshift-spec.md`로 이동 및 문서 인덱스(`docs/README.md`) 신설.
