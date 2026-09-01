# 변경 이력 (Changelog)

이 프로젝트의 모든 주요 변경 사항은 이 문서에 기록됩니다.

형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/)를 따르며,
이 프로젝트는 [Semantic Versioning (유의적 버전 2.0.0)](https://semver.org/lang/ko/)을 준수합니다.

## [Unreleased]

### 추가 (Added)
- `SKILL.md`와 프로젝트 spec에 spawn 전 의미·동작·범주·외부 계약을 부모가 확정하도록 하는 Semantic Decision Closure 규칙 추가.
- `SKILL.md`, Task Capsule template 및 `README.md`의 Capsule 형식에 parent-only Pre-spawn check와 의미적 Acceptance Criteria 작성 지침 추가.
- `delegation-examples.md`에 문서의 MVP/장기 확장 범주를 보존하는 Bad/Good 사례 추가.

### 변경 (Changed)
- 정확한 문구·분류·literal·고정 코드 블록이 계약인 작업에서는 `Exact change`를 필수로 제공하도록 규칙 강화.
- reasoning effort는 실행 복잡도만 조절하며 Luna의 의미적·제품·아키텍처 결정 권한을 확장하지 않는다는 불변 규칙 명문화.

## [0.1.3] - 2026-08-31

### 추가 (Added)
- `SKILL.md`: 위임 적격성을 보조하는 8대 기본 필수 요건(Baseline Requirements) 및 3대 안전성 신호(Coupling, Verification, Consequence) 정성적 체크리스트 추가.
- `SKILL.md`: Validation Budget 및 Luna 자체 구현 실수 시 최대 1회 복구(Recovery Limit) 정책 명문화.
- `SKILL.md` & `delegation-examples.md`: 외부 부수효과 및 승인 필요 작업(`git push`, `deploy`, `secret` 등) 발생 시 `NEEDS_PARENT_ACTION` 프로토콜 추가.
- `SKILL.md`: Parent의 Child Lifecycle 종료 확인(Terminal State 검증 및 잔여 워커 중단) 규칙 추가.
- `SKILL.md`: 실제 spawn 시에만 간결하게 출력하는 Downshift Notice(`Codex Downshift | Luna / medium | <task_name>`) 가이드라인 추가.
- `delegation-examples.md`: 12대 핵심 실전 시나리오로 매트릭스 및 본문 확장 (Recovery Limit, `NEEDS_PARENT_ACTION` 추가).
- `README.md`: `npx skills update` 업데이트 안내 및 Windows fallback 안내 추가.
- `README.md` & `docs/`: `codex-auto-model-router`에 대한 독립적 영감 출처 및 Acknowledgements 섹션 추가.

### 변경 (Changed)
- `task-capsule-template.md`: Recovery policy 및 이원화된 에스컬레이션 프로토콜(`NEEDS_PARENT_DECISION`, `NEEDS_PARENT_ACTION`) 반영.
- `README.md`: 문서 구조를 표준 순서(소개 ➔ 동작원리 ➔ 설치 ➔ 업데이트 ➔ 안전성 ➔ 예시 ➔ 문서 ➔ Acknowledgements ➔ License)로 최적화.

## [0.1.2] - 2026-08-31

### 추가 (Added)
- `SKILL.md` & `delegation-examples.md`: Trivial task delegation과 Bounded task 묶음 위임(Batching)에 관한 일관된 정책 및 10대 실전 시나리오 1:1 완벽 매핑.
- `SKILL.md`: `reasoning_effort` 기본값(`medium`) 및 low/medium/high 선택 기준과 xhigh/max 무분별 사용 방지 가이드라인 명시.

### 변경 (Changed)
- `SKILL.md`: Trivial task 위임 규칙 간의 모순 해소 (Latency보다 Parent Usage 절감 우선, 단일 atomic action 오버헤드 예외 및 배치 위임 원칙 확립).
- `docs/codex-downshift-spec.md`: 기획 명세서의 상태(v0.1.2 완료), Spawn Contract, Trivial Task 정책, 10대 시나리오 및 MVP 구현 현황 체크리스트 최신화 동기화.
- 프로젝트 전체: "Luna 등", "경량 모델들" 등 다중 모델 자동 선택으로 오해될 수 있는 표현을 `Luna` (`gpt-5.6-luna`) 단일 모델로 일괄 정돈.

## [0.1.1] - 2026-08-31

### 추가 (Added)
- `SKILL.md`: 실제 Codex Native Subagent 생성을 위한 Downshift Spawn Contract 명시 (`model = "gpt-5.6-luna"`, `fork_turns = "none"`, `reasoning_effort`, `task_name`).
- `SKILL.md`: Luna spawn 실패 시 상위 모델로의 대체나 `model` 생략 child 재시도 없이 부모 모델이 직접 수행하는 Fail-Closed Fallback Invariant (불변 규칙) 추가.
- `SKILL.md`: Luna 작업 완료 후 부모 모델의 중복 작업 및 동일 테스트 재실행 방지 지침 추가.
- `SKILL.md`: `superpowers:writing-skills` 표준에 맞춘 **합리화 방지 테이블 (Rationalization Table)**, **Red Flags 위험 신호 목록**, **Decision Flowchart 다이어그램** 내장.
- `references/delegation-examples.md`: 핵심 검증 시나리오 매트릭스 및 실전 예시집 전면 보강.

### 변경 (Changed)
- `SKILL.md`: YAML Frontmatter `description`을 `superpowers` SDO(Skill Discovery Optimization) 표준에 맞추어 순수 트리거 조건(`Use when...`)에 집중하도록 정제.
- `task-capsule-template.md`: 부모 CoT/대화 제외 및 최소 컨텍스트 기반(Minimal Self-Contained Context) 토큰 효율 작성 원칙 반영.
- `README.md` & `docs/`: 설치 경로 정책 분리 (글로벌은 타 에이전트 오인식 방지를 위한 `~/.codex/skills/`, 프로젝트는 `.agents/skills/`).
- `README.md` & `SKILL.md`: "Luna 등" 모호한 표현을 `Luna` (`gpt-5.6-luna`) 단일 모델로 정돈하고, 과장된 성능 표현 완화 및 Leaf Worker 지침 레벨 제약(Policy Constraint) 성격 명문화.

## [0.1.0] - 2026-08-31

### 추가 (Added)
- `codex-downshift` 초기 프로젝트 구조 구성.
- `skills/codex-downshift/SKILL.md`: Sol/Terra 부모 모델에서 확정된 실행 작업을 Luna로 다운시프트(위임)하는 핵심 프롬프트 스킬.
- `skills/codex-downshift/references/delegation-examples.md`: 실제 위임 시 모범 사례(Good) 및 안티패턴(Bad) 예시집.
- `skills/codex-downshift/references/task-capsule-template.md`: 한정된 작업 위임을 위한 Self-Contained 프롬프트 캡슐 표준 서식.
- `README.md`, `CONTRIBUTING.md`, `.gitignore` 등 기본 개발 환경 및 문서 구축.
- 원본 기획 문서를 `docs/codex-downshift-spec.md`로 이동 및 문서 인덱스(`docs/README.md`) 신설.
