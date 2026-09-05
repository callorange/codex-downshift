# 변경 이력 (Changelog)

이 프로젝트의 모든 주요 변경 사항은 이 문서에 기록됩니다.

형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/)를 따르며,
이 프로젝트는 [Semantic Versioning (유의적 버전 2.0.0)](https://semver.org/lang/ko/)을 준수합니다.

## [Unreleased]

### 추가 (Added)
- **Parent Direct routing notice**: Gate A → Gate B → Economic Gate 평가를 수행한 최종 Parent Direct도 기존 Spawn Notice 호환 형식으로 한 번 표시하고, Child delegation·비적용 요청·spawn 실패의 notice 횟수 규칙을 명시.
- **Economic Gate 및 준비 테스트**: Parent 준비·Child 실행·Parent 검증의 Effective Downshift Cost와 Parent Direct Cost를 비교하는 네 가지 필요조건과 human steering·rework·verification을 포함한 실제 작업 비용 관점을 명시. 2× Luna/3× Terra는 라우팅 기준이 아닌 근거 미확정 운영 가설로 비용 문서에만 보존.
- **Luna all-matches 안전장치 및 micro-batch**: bounded Search 전체 매치와 non-exhaustive examples 규칙, 항목별 완료 형식을 추가.
- **Spawn visibility 및 최소 capsule 문맥**: `[codex-downshift] → <model> (<effort>) | <task_name> | <brief reason>`과 Search/Modify/Apply 및 Minimum Sufficient Context를 명시.
- **모델 근거·추천 참조 문서 분리 및 `SKILL.md` Token Diet**: 공식 요율·추정 지수·위임 비용 모델은 `model-economics.md`, 외부 관측은 `model-benchmarks.md`, 종합 추천은 `model-selection.md`로 분리. 라우팅 사례와 terminal/recovery 사례도 별도 문서로 나누고 `SKILL.md`에는 핵심 실행 계약과 on-demand 읽기 조건만 유지.
- **Sol-Parent Golden Switch 규칙 정밀화**: implementation-local 선택을 Terra에 맡기는 역할 정책을 명시하고 Sol Parent 전용으로 분기. 추정 지수·Steps와 금전 비용의 비교 기준을 구분하며 시간·allowance 절감 보장으로 해석하지 않음.

### 변경 (Changed)

- **Artificial Analysis 성능 근거와 추천 갱신**: GPT-5.6의 모델·추론 레벨별 Intelligence Index와
  Codex Coding Agent Index·task당 token을 기록하고, 공식 요율·Estimated Consumption Index·권한 경계와
  함께 해석해 Luna·Terra·Sol의 작업별 추천 기준을 보완. Luna Medium은 Implementation Closed 상태에서
  bounded search 또는 검증 실패에 Parent가 고정한 Rule로 대응하는 1회 복구가 실질적 실행량일 때의 후보로 정밀화.
  비용과 점수는 대체로 함께 증가하지만 비례하지 않는다는 적용 경계를 명시하고, 기획 명세의 중복 수치표는 기준 문서 링크로 대체.
  기존 위임 경로·판단 권한·공식 요율·추정 지수 수치는 유지.

- **공식 Token-Credit Rate 표 정리**: OpenAI 공식 표의 열 이름과 credits 단위를 그대로 반영하고,
  Luna 대비 상대 배수는 공식 값과 구분한 프로젝트 해석으로 이동. 기존 요율 수치는 유지.

- **설치 패키지와 근거 정합성**: 완결된 Capsule을 references로 이동하고 Child 메시지에 all-matches 완료 증거를 포함. High 예외에도 모든 Gate·권한 제한을 적용하고 수동·CLI 설치 안내를 구분. 기존 추정 지수의 Git 이력과 산출 재현 미확인 범위를 기록하며 수치는 보존.

- **실행 계약 정합성 보완**: 선택한 Luna effort를 spawn에 유지하고 경제성 도식에 추가 작업 비용을 반영. Exact와 all-matches의 탐색 경계를 분리하고 축약 Capsule의 worker 제한·고정 docstring·검증 절차를 보완.

- **외부 평가 데이터 및 Sol Light 추천**: Model Economics에 CursorBench·Instavar·Sonar의 출처·관측값·한계를 기록. Sol Light를 Sol Medium 대비 사용량 절충안으로 추가하고 Golden Switch의 비용 기준을 관련 문서에 동기화. 공식 요율·기존 추정 지수 및 위임 허용 경로는 유지.

- **추론 레벨 표기 통일**: 일반 설명은 Light·Medium·High·XHigh·Max, 설정·호출 및 Routing Notice는 실제 인자값을 사용하도록 정리하고 루트 AGENTS.md의 Project Rules에 기록. Light의 호출값 `low`와 과거 릴리스 기록은 보존.

- **모델 경제성 참고 가이드 보완**: Terra Medium의 일반 구현 기본 추천과 Sol Medium의 조건부 우선 고려를 사용자용 참조에 정리하고, Luna Light/Medium/High 및 Terra·Sol Light의 비용·역할·평가 한계를 보완. SKILL에는 Parent 선택 안내를 넣지 않고 기존 하향 위임 역할을 유지. 실제 작업 비용에 human steering·rework·verification을 반영하며 공식 요율·추정 지수와 routing 권한은 보존.
- **조건·동작 비교표 보완**: Routing Notice, 모델별 후보·권한, 반환 상태, 완료 근거를 선행 조건과 예외를 포함한 표로 정리하고 시나리오 요약에 12–16번 및 복구 미시도 경우를 반영.
- **스킬 문서 구조화**: 불변 규칙과 실행 단계를 제목으로 구분하고, 조건·권한·동작·fallback 및 모델별 지침을 묶어 표현. 긴 합리화 방지 표를 사례별 설명으로 전환하고 코드 블록·비용 수치·frontmatter·출력 형식은 보존.
- **README 사용 흐름 개선 및 상세 내용 보존**: 빠른 시작·사용 예시와 함께 라우팅 도식, spawn 계약, 비용·절감률 비교표, 캐시 계산 및 Task Capsule 서식을 제공. 비용 snapshot과 참조 근거를 표시하고 수동 설치 경로와 공유 경로 설명을 공식 문서에 맞춰 수정.
- **라우팅 정책 동기화**: Gate A → Gate B → Economic Gate로 전환하고 LOC threshold·단일 deterministic validation과 test/fix loop를 자동 위임 조건이 아닌 보조 신호로 구분.
- **공식 요율과 추정 소모 지수 분리**: 공식 token-credit rate와 결합 추정치인 **Estimated Codex Consumption Index**를 엄격히 분리하고 `[!IMPORTANT]` 주의문구 명시.
- **절감률 표현 객관화**: Sol Medium 단일 기준선 의존을 탈피하고, Sol Light(9.40×) 및 Sol Medium(18.04×) 대비 추정 지수상 상대 절감률을 객관적으로 병기.
- **프롬프트 캐시 계산 단위 보정**: Sol 40k cached context(0.4 credits) 및 Luna 3k uncached input(0.015 credits)의 크레딧 단위 오류 수정.
- **Terra Child 기본 reasoning 단순화**: Terra Child의 자동 디스패치 reasoning effort를 `medium`으로 단일화하고 구 raw-token 배율 잔재 제거.
- **핵심 문서 최신화**: README, 기획 명세, 문서 인덱스, 기여 가이드의 역할과 기준 문서를 명확히 하고 현재 실행 규칙·비용 근거·표기 정책에 동기화.

### 수정 (Fixed)
- **보조 신호와 위임 조건 구분**: 단순 수정·파일 수·새 분석 여부만으로 경로를 단정하던 표현을 안전성·권한·경제성 조건으로 정렬. 2×/3×는 실행 지침에서 제외하고 비용 문서에 근거 미확정의 운영 가설로 명시.
- **Micro-batch 개수 제한 제거**: 근거 없는 3–5개 조건을 복수 항목의 독립성·권한·묶음 처리 경제성으로 대체하고, 실제 위임의 Gate 통과 조건을 명시. 숫자는 구체적 예시에만 유지.
- **위임 계약 정합성**: 네 경제성 질문의 충족을 위임 필요조건으로 통일하고 Gate 실패 시 Parent Direct, 배치 후보와 실제 위임의 조건을 동기화. `Apply`와 구현 재량을 분리하고 필요한 경우의 완료 대상·탐색 근거 및 명령 외 검증 절차를 스킬·README·명세·예시에 반영.
- **`docs/codex-downshift-spec.md` Reasoning Effort 불변 규칙 동기화**: Invariant 7의 단일 medium 기본값 표기를 최신 Luna Light(기본)/Medium(경량탐색) 및 Terra Medium(Sol Parent 전용 구현 워커) 정책과 정확히 일치하도록 동기화.
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
