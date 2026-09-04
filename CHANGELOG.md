# 변경 이력 (Changelog)

이 프로젝트의 모든 주요 변경 사항은 이 문서에 기록됩니다.

형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/)를 따르며,
이 프로젝트는 [Semantic Versioning (유의적 버전 2.0.0)](https://semver.org/lang/ko/)을 준수합니다.

## [Unreleased]

### 추가 (Added)
- **Parent Direct routing notice**: Gate A → Gate B → Economic Gate 평가를 수행한 최종 Parent Direct도 기존 Spawn Notice 호환 형식으로 한 번 표시하고, Child delegation·비적용 요청·spawn 실패의 notice 횟수 규칙을 명시.
- **Economic Gate 및 준비 테스트**: Parent 준비·Child 실행·Parent 검증의 Effective Downshift Cost와 Parent Direct Cost를 비교하고, 2× Luna/3× Terra를 비공식 잠정 운영 휴리스틱으로 명시.
- **Luna all-matches 안전장치 및 micro-batch**: bounded Search 전체 매치와 non-exhaustive examples 규칙, 항목별 완료 형식을 추가.
- **Spawn visibility 및 최소 capsule 문맥**: `[codex-downshift] → <model> (<effort>) | <task_name> | <brief reason>`과 Search/Modify/Apply 및 Minimum Sufficient Context를 명시.
- **전용 경제학 참조 문서(`references/model-economics.md`) 신설 및 `SKILL.md` Token Diet**: 공식 크레딧 요율, 추정 소모 지수, 벤치마크 데이터 및 캐시 계산을 전용 참조 문서로 분리하여 `SKILL.md` 크기를 약 4KB(17%) 감축.
- **Sol-Parent Golden Switch 규칙 정밀화**: Luna High(6.00×, 40 steps) 대비 Terra Medium(5.35×, 20 steps)의 시간 및 소모 효율 우위(CursorBench 3.2 근거)를 명시하고, Sol Parent 전용 규칙(Terra Parent는 Terra Direct)으로 분기.

### 변경 (Changed)
- **라우팅 정책 동기화**: Gate A → Gate B → Economic Gate로 전환하고 LOC threshold·단일 deterministic validation과 test/fix loop를 자동 위임 조건이 아닌 보조 신호로 구분.
- **공식 요율과 추정 소모 지수 분리**: 공식 token-credit rate와 결합 추정치인 **Estimated Codex Consumption Index**를 엄격히 분리하고 `[!IMPORTANT]` 주의문구 명시.
- **절감률 표현 객관화**: Sol Medium 단일 기준선 의존을 탈피하고, Sol Low(9.40×) 및 Sol Medium(18.04×) 대비 추정 지수상 상대 절감률을 객관적으로 병기.
- **프롬프트 캐시 계산 단위 보정**: Sol 40k cached context(0.4 credits) 및 Luna 3k uncached input(0.015 credits)의 크레딧 단위 오류 수정.
- **Terra Child 기본 reasoning 단순화**: Terra Child의 자동 디스패치 reasoning effort를 `medium`으로 단일화하고 구 raw-token 배율 잔재 제거.
- 핵심 문서(`README.md`, `docs/codex-downshift-spec.md`, `SKILL.md`, `delegation-examples.md`) 및 런타임 config 전면 동기화.

### 수정 (Fixed)
- **`docs/codex-downshift-spec.md` Reasoning Effort 불변 규칙 동기화**: Invariant 7의 단일 medium 기본값 표기를 최신 Luna Low(기본)/Medium(경량탐색) 및 Terra Medium(Sol Parent 전용 구현 워커) 정책과 정확히 일치하도록 동기화.
- **`model-economics.md` Codex credit-rate 직접 출처 URL 추가 및 역할 분리**: OpenAI Help Center 직접 출처(`https://help.openai.com/en/articles/11481834`)를 추가하고, API pricing 참고용 URL 및 벤치마크 출처의 역할을 엄격히 분리 명시.

## [0.1.4] - 2026-09-02

### 추가 (Added)
- **10대 핵심 불변 규칙 (10 Core Invariants)** 정립 및 `SKILL.md` 토큰 다이어트(Token Diet) 적용.
- **2단계 결정적 라우팅 파이프라인**: Gate A (Delegation Safety Gate) ➔ Gate B (Decision Authority Gate) 2단계 안전 검증 도입.
- **역할별 계층형 하향 위임 (Tiered Downshift)**: `Sol ➔ Terra / Luna` 및 `Terra ➔ Luna` 하향 위임 지원.
- **역할별 위임 권한 (Role-Based Child Delegated Authority)**: Active Parent (상위 판단 소유) vs Terra Child (로컬 구현 분석/선택) vs Luna Child (확정된 기계적 실행).
- **4대 표준 Terminal Return Protocols**: `TASK_COMPLETED` (다중 검증 지원), `TASK_FAILED` (1회 복구 실패 또는 복구 미시도 후 작업트리 보존), `NEEDS_PARENT_DECISION`, `NEEDS_PARENT_ACTION` 표준화 (`task-capsule-template.md`).
- **11대 핵심 실전 행동 시나리오 (Behavioral Specifications)**: High Consequence Gate A 차단, Gate B 모델 라우팅, 4대 반환 프로토콜, Fail-Closed Fallback 등 11대 시나리오 구축 (`delegation-examples.md`).
- **Scope-Matched Fresh Verification**: `Verification scope MUST match the completion claim scope` 원칙에 따른 Parent의 독립 최소 직접 검증 표준화.
- **Reasoning Effort 정책**: `low`/`medium` 자동 기본값, `high`/`xhigh`/`max` 사용자 명시적 승인 프로토콜 명문화.

### 변경 (Changed)
- Downshift Only 정의 명확화: 상향 위임 및 동일 티어 재위임 금지, No Chaining(`Sol ➔ Terra ➔ Luna` 금지) 명시.
- `docs/codex-downshift-spec.md` 및 `README.md` 전면 최신화 동기화.

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
