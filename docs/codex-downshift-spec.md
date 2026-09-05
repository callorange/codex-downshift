# codex-downshift — Project Specification

> Status: v0.1.4 release baseline + Unreleased design updates (2026-09-05)
> Target: OpenAI Codex  
> Document role: 프로젝트의 설계 의도·정책 근거·성공 기준을 보존하는 기획 명세.
> 실제 실행 규칙은 `SKILL.md`, 비용 수치는 `model-economics.md`, 외부 관측은 `model-benchmarks.md`, 설정 추천은 `model-selection.md`, 설치 절차는 `README.md`를 기준으로 한다.

---

## 1. 프로젝트 이름 및 설명

### Repository name
`codex-downshift`

### GitHub description

**English**
> A lightweight Codex skill that keeps Sol or Terra as the parent and offloads (downshifts) bounded execution tasks to Luna (`gpt-5.6-luna`) or Terra (`gpt-5.6-terra`) to reduce usage and costs.

**한국어**
> Sol 또는 Terra를 부모 모델로 유지하면서 Gate A → Gate B → Economic Gate를 통과한 실행 작업만을 Luna (`gpt-5.6-luna`) 또는 Terra (`gpt-5.6-terra`)로 다운시프트(하향 위임)해 Codex 사용량을 절감하는 경량 Skill.

### 이름 선정 이유

이 프로젝트는 단순한 `model router`나 특정 모델에만 종속된 도구가 아니다.

- 사용자가 선택한 Sol/Terra를 다른 모델로 교체하지 않는다.
- 작업마다 "최적 모델"을 찾는 복잡한 라우팅이 목적이 아니다.
- 상위 모델의 판단이 끝난 실행 작업만 하위 경량 워커로 안전하게 다운시프트(하향 위임)한다.
- 하위 워커에서 Terra/Sol로 자동 escalation하지 않는다.

따라서 `downshift`가 상위 모델의 판단 통제 하에 실행 비용을 낮추는 실제 역할을 가장 정확하게 표현한다.

---

## 2. 프로젝트 목표

`codex-downshift`는 사용자가 Codex에서 Sol 또는 Terra를 주력(부모) 모델로 사용할 때,
이미 판단이 끝나고 범위가 명확해진 실행 작업을 Luna (`gpt-5.6-luna`) 또는 Terra (`gpt-5.6-terra`) 서브에이전트에 넘겨
상위 모델의 사용량과 비용을 줄이는 경량 Codex Skill이다.

핵심 질문은 하나다.

> **현재 부모 모델이 처리하려는 하위 작업 중, 상위 판단을 다시 하지 않고 하위 워커가 안전하게 실행할 수 있는 작업이 있는가?**

- 있다면: Gate A Safety ➔ Gate B Decision Authority ➔ Economic Gate를 거쳐 적합한 하위 모델(Luna 또는 Terra)에 위임하거나, 경제성이 비슷하면 Parent Direct로 처리한다.
- 없다면: 현재 부모 모델이 직접 처리한다.

---

## 3. 해결하려는 문제

Sol과 Terra는 높은 품질의 추론과 구현 능력을 제공하지만 Codex 사용량 제한을 빠르게 소비할 수 있다.

특히 다음과 같은 개발 과정에서는 실제 코드 변경량보다 반복 추론과 실행 과정의 비용이 커질 수 있다:

- TDD의 RED → GREEN → REFACTOR 반복
- 명확한 테스트 코드 작성
- 이미 결정된 구현의 실제 코드 작성
- 반복적인 코드 및 직렬화 필드 수정
- docstring/문서 수정
- deterministic lint/type 오류 수정
- 특정 테스트 및 검증 명령 반복 실행

많은 경우 상위 모델은 이미 다음 작업을 완료한 상태다:

1. 사용자의 의도 이해
2. 관련 코드 조사
3. 아키텍처 및 구현 방향 결정
4. 수정할 파일/심볼 결정
5. 동작과 acceptance criteria 결정
6. 검증 방법 결정

이 상태에서도 직접 수행과 위임의 비용을 비교해야 한다. Gate A/B를 통과한 작업에서 부모의 준비·검증 부담이 대체 실행량보다 명확히 작다면, 확정된 실행을 하위 모델에 맡겨 사용량을 줄일 수 있다.
`codex-downshift`는 상위 판단 권한을 온전히 보존하면서 그 마지막 실행 단계를 하위 워커에 안전하게 offload하는 것을 목표로 한다.

---

## 4. 10대 핵심 불변 규칙 (10 Core Invariants)

> **"Safe enough to delegate → delegate only the remaining authority → keep every child leaf-only → return structured evidence → let the Parent make only claims it freshly verified."**

1. **Parent Authority (부모 모델 권한 보존)**: 사용자가 선택한 Active Parent(Sol 또는 Terra)는 요구사항 해석, 제품 동작, 아키텍처, Public API, 보안, 호환성 등 모든 상위 미결 판단을 직접 소유한다. Parent 역할 자체는 Child에게 위임되지 않는다.
2. **Downshift Only (단방향 하향 위임)**: Child는 Active Parent보다 동일하거나 높은 tier의 모델을 새로 spawn/invoke할 수 없다.
   - **허용**: `Sol Parent ➔ Terra Child`, `Sol Parent ➔ Luna Child`, `Terra Parent ➔ Luna Child`
   - **금지**: `Sol Parent ➔ Sol Child`, `Terra Parent ➔ Terra Child`, `Terra Child ➔ Sol`, `Luna Child ➔ Terra/Sol`
   - *(단, Child가 `NEEDS_PARENT_*` 또는 `TASK_FAILED`로 Parent에게 제어권을 반환하는 것은 상향 위임이 아니며 정상 프로토콜임)*
3. **Safety Before Routing (Gate A → Gate B → Economic Gate)**: 모델 선택 전에 **Gate A (Delegation Safety Gate)**를 통과하고, Gate B에서 남은 권한별 후보를 고른 뒤 Economic Gate에서 준비·검증 오버헤드보다 leverage가 클 때만 위임한다. 저위험·가역적·검증 가능한 작업이 아니면 **Parent Direct**.
4. **Role-Based Child Delegated Authority (역할별 위임 권한)**:
   - **Luna Child**: `Semantic Closed` + `External Contract Closed` + `Implementation Closed`. 구현 패턴과 방법까지 확정된 기계적 실행 전담.
   - **Terra Child**: `Semantic Closed` + `External Contract Closed` + `Implementation-Local Decision Remains`. 외부 계약은 확정되었으나 내부 구현 분석 및 선택이 필요한 경우 전담 (Sol Parent 전용).
5. **Leaf Worker / No Chaining**: 모든 Child는 Leaf Worker이며 다른 agent나 model을 spawn/invoke/delegate할 수 없다. `Sol ➔ Terra ➔ Luna` 다단계 체이닝 금지.
6. **Fail Closed**: Child spawn 실패, 라우팅 모호성, 또는 권한 불확실 시 다른 하위 모델로 우회하지 않고 **부모 모델이 직접 수행**.
7. **Reasoning Effort & Model Policy (Luna-First & Sol-Parent Golden Switch)**:
   - **Luna Child**: 기본값은 Light (`reasoning_effort = "low"`). `Implementation Closed` 상태에서 bounded search 또는 검증 실패를 해석해 Parent가 고정한 Rule로 대응하는 1회 복구가 실행의 실질적 부분이면 `medium`을 후보로 삼는다.
   - **Terra Child**: 기본값은 `medium`. Sol Parent에서 `Implementation-Local Decision Remains`인 작업에 사용한다.
   - **Sol-Parent Golden Switch**: Implementation-local 분석/선택이 필요한 경우 Luna의 reasoning effort를 `high`로 올리지 않고 Terra Medium Child를 우선한다.
   - **Terra Parent**: 동일 tier child를 생성하지 않으므로 implementation-local decision이 남은 작업은 Terra Parent가 직접 수행한다.
   - **Automatic selection prohibited**: `high` / `xhigh` / `max`는 자동 선택하지 않는다. 사용자가 명시적으로 요청하거나 승인한 경우에만 exceptional override로 허용한다.
   - *Reasoning effort 상승은 Child에게 위임된 Decision Authority를 확장하지 않는다.*
8. **Max 1 Recovery**: Child validation 실패 시 자체 구현 수정은 가능한 경우에 한해 최대 1회만 허용(환경/의존성 등 부적절한 경우 미시도). 재실행 실패 또는 미시도 시 즉시 `TASK_FAILED`로 중단.
9. **Structured Return Protocols**: Child는 반드시 4대 반환 프로토콜(`TASK_COMPLETED`, `TASK_FAILED`, `NEEDS_PARENT_DECISION`, `NEEDS_PARENT_ACTION`) 중 하나로 종료하며, 임의로 destructive rollback(`git reset --hard` 등)을 수행하지 않음.
10. **Evidence Before Completion (Scope Matching)**: Parent는 Child 결과를 Blind Trust하지 않으며, **자신이 하려는 Completion Claim의 범위와 정확히 일치하는 Minimum Sufficient Fresh Verification을 직접 수행**.

---

## 5. 지원 부모 모델 및 계층형 매트릭스

| 부모 모델 (Active Parent) | 위임 대상 (Child) | 대상 작업 성격 (Decision Authority) |
| :--- | :--- | :--- |
| **Sol** | ✅ **`gpt-5.6-luna`** | `Semantic Closed` + `Implementation Closed` (단순 TDD 반복, docstring, 정형 린트/타입 수정 등 기계적 실행) |
| **Sol** | ✅ **`gpt-5.6-terra`** | `Semantic Closed` + `Implementation-Local Decision Remains` (외부 계약 확정, 내부 로컬 알고리즘/구현 선택 위임) |
| **Terra** | ✅ **`gpt-5.6-luna`** | `Implementation Closed` (정형 docstring, 린트/타입 수정, 단순 단위 테스트 등 기계적 실행) |
| **Terra** | 🛑 **Terra Direct** | 구현 판단이 남은 작업은 Downshift Only 원칙에 따라 Terra 부모가 직접 수행 |
| **Luna** | ❌ **비활성화** | 사용자가 Luna를 주 모델로 선택한 경우 상위 모델 자동 호출 없음 (직접 처리) |
| **기타 모델** | ❌ **비활성화** | 지원하지 않는 모델 환경에서는 자동 위임을 비활성화하고 부모가 직접 수행 |

---

## 6. 결정적 라우팅 파이프라인 (Gate A → Gate B → Economic Gate)

```text
Active Parent (Sol or Terra)
  │
  ├─ 1. 상위 판단 미결 (Semantic / Architecture / Security)?
  │    YES ──────────────────────────────────────────→ Parent Direct (상위 추론/판단 직접 수행)
  │    NO (상위 판단 완료)
  ▼
┌──────────────────────────────────────────────────────────┐
│ Gate A: Delegation Safety Gate                           │
│ - Bounded: 수정 범위와 영향 표면을 충분히 특정 가능한가?          │
│ - Verifiable: 객관적 Acceptance와 결정적 검증 수단이 있는가?    │
│ - Limited Consequence: 실패 영향이 국소적/가역적인가?         │
│ - No High-Impact: 보안/권한/DB Migration/배포/파괴적 변경 배제│
└────────────────────────────┬─────────────────────────────┘
                             │
            ANY NO (위험/모호) ┴──────────────→ Parent Direct (Fail-Closed)
                             │ ALL PASS
                             ▼
┌──────────────────────────────────────────────────────────┐
│ Gate B: Decision Authority Gate                          │
│                                                          │
│ (Active Sol Parent)                                      │
│ ├─ Implementation-local 분석/선택 남음                    │
│ │  ──────────────────────────→ Terra Medium Child (5.35×)│
│ ├─ Implementation 닫힘 + bounded search/고정 복구 필요    │
│ │  ──────────────────────────→ Luna Medium Child (2.61×) │
│ └─ Implementation까지 닫힌 기계적 조립/테스트              │
│    ──────────────────────────→ Luna Light Child (1.00×)  │
│                                                          │
│ (Active Terra Parent)                                    │
│ ├─ Implementation-local 분석/선택 남음                    │
│ │  ──────────────────────────→ Terra Parent Direct       │
│ ├─ Implementation 닫힘 + bounded search/고정 복구 필요    │
│ │  ──────────────────────────→ Luna Medium Child (2.61×) │
│ └─ Implementation까지 닫힌 기계적 조립/테스트              │
│    ──────────────────────────→ Luna Light Child (1.00×)  │
└──────────────────────────────────────────────────────────┘
                             │ candidate selected
                             ▼
┌──────────────────────────────────────────────────────────┐
│ Economic Gate: Delegation Preparation Test                │
│ Four preparation conditions pass AND net benefit remains │
│ → selected Child; otherwise → Parent Direct              │
└──────────────────────────────────────────────────────────┘
```

### 6.1 Routing signals and Economic Gate
LOC·파일 수는 약한 secondary signal일 뿐이며 Parent Direct 또는 delegation을 독립적으로 결정하지 않는다. trivial literal/mechanical edit, fixed-rule bounded execution, bounded search, 예상 test/fix loop, implementation-local decision, high-consequence/irreversible work 같은 관찰 가능한 작업 속성이 라우팅을 이끈다. Gate A와 Gate B 후 Economic Gate에서 Delegation Preparation Test 네 조건을 모두 확인한다.

Luna Light는 구현과 target locations가 닫힌 기계적 실행, Luna Medium은 구현이 닫힌 상태에서 parent-fixed Match Rule에 따른 bounded Search 또는 검증 실패에 고정 Rule로 대응하는 1회 복구가 실행의 실질적 부분인 작업이다. 단순 검증 명령 실행만으로 Medium을 선택하지 않는다. `all matches`는 Search 경계 전체를 검사하고 non-exhaustive examples를 전체 목록으로 오인하지 않는다. Terra Medium은 Sol Parent에서 외부 계약은 고정됐지만 implementation-local 선택이 남은 경우에만 후보이며, Terra Parent는 직접 처리한다. 후보여도 경제성이 비슷하면 Parent Direct다.

### 6.2 Parent Direct 조건
- high-consequence/irreversible work는 Gate A에서 Parent Direct로 처리한다.
- 저위험·가역적인 trivial literal/mechanical edit는 Gate A 통과 후 Gate B에서 후보를 선정한다. Economic Gate의 Delegation Preparation Test를 충족하지 못하면 Parent Direct로 처리한다.
- LOC·파일 수는 약한 secondary signal이며 경로를 독립적으로 결정하지 않는다.

### 6.3 Routing Notice
Gate A → Gate B → Economic Gate routing 평가를 실제로 수행했을 때만 최종 결정 하나를 `[codex-downshift] → <model> (<effort>) | <task_name> | <brief reason>` 형식으로 정확히 한 번 사용자에게 표시한다. Child delegation은 spawn 직전 기존 notice를 사용한다. Parent Direct도 `[codex-downshift] → Parent Direct | <task_name> | <first decisive gate or brief reason>`로 표시하되, Gate A·Gate B·Economic Gate 전체가 아니라 최종 결정을 만든 첫 번째 결정적 gate 또는 이유만 짧게 담는다. 스킬이 적용되지 않아 routing 평가가 없으면 notice를 출력하지 않으며, spawn 실패도 추가 routing notice를 만들지 않는다. 출력의 canonical 규칙은 `skills/codex-downshift/SKILL.md`다.

---

## 7. 프로젝트 파일 구조

`codex-downshift`는 외부 런타임 의존성 없이 순수 Agent Skills 표준에 따라 간결하게 구성된다.

```text
codex-downshift/
├── .gitignore
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
├── AGENTS.md
├── docs/
│   ├── README.md
│   └── codex-downshift-spec.md
└── skills/
    └── codex-downshift/
        ├── SKILL.md
        └── references/
            ├── delegation-examples.md
            ├── model-benchmarks.md
            ├── model-economics.md
            ├── model-selection.md
            ├── terminal-scenarios.md
            └── task-capsule-template.md
```

### 필요하지 않은 것 (Non-Essentials)
- 별도 daemon, background server, wrapper script
- 복잡한 config TOML 또는 custom agent TOML
- 별도 Python/Node 런타임 엔진
- Codex의 기본 Multi-Agent 기능(`spawn_agent`)을 프롬프트 지침 수준에서 제어한다.

---

## 8. 동적 생성 및 Downshift Spawn Contract

부모 모델이 위임 시점에 Codex의 native subagent 기능을 사용하며, 모델 상속을 방지하기 위해 다음 매개변수를 반드시 명시한다:

```text
# 1) Sol ➔ Luna 또는 Terra ➔ Luna (기계적 조립/테스트)
spawn_agent(
    model = "gpt-5.6-luna",          # [필수] 부모 모델 상속 방지
    fork_turns = "none",             # [필수] 부모 대화 제외, fresh context
    reasoning_effort = "low",        # [필수] 기본값: low (bounded 탐색·고정 복구 시 medium)
    task_name = "<task_name>",
    message = "<Task Capsule>"
)

# 2) Sol ➔ Terra (로컬 구현 위임, Sol Parent 전용)
spawn_agent(
    model = "gpt-5.6-terra",         # [필수] Terra 모델 명시
    fork_turns = "none",             # [필수] 부모 대화 제외, fresh context
    reasoning_effort = "medium",     # [필수] 기본값: medium
    task_name = "<task_name>",
    message = "<Task Capsule>"
)
```

### 8.1 Fail-Closed Fallback Invariant (불변 규칙)
- Child 생성이 실패하거나 미지원 환경인 경우:
  - 타 모델로 우회하거나 `model`을 생략한 child를 재시도하지 않는다.
  - **현재 부모 모델(Sol/Terra)이 해당 작업을 직접 계속 수행한다.**

### 8.2 Estimated Codex Consumption Index 및 Reasoning Effort 정책

공식 Token-Credit Rate, Estimated Consumption Index와 캐시 계산은
[Model Economics](../skills/codex-downshift/references/model-economics.md)를 기준으로 한다.
외부 평가 원시 관측은 [Model Benchmarks](../skills/codex-downshift/references/model-benchmarks.md),
비용·성능·실제 작업 부담을 종합한 설정 조언은
[Model Selection Guide](../skills/codex-downshift/references/model-selection.md)를 따른다.

이 명세가 유지하는 정책은 다음과 같다.

- 스킬은 이미 선택된 Active Parent를 유지하며 Parent 모델을 추천하거나 자동 전환하지 않는다.
- Luna Light는 target과 구현이 닫힌 기계적 실행의 기본값이다.
- Luna Medium은 구현과 Match Rule이 닫힌 상태에서 bounded search 또는 검증 실패에 고정 Rule로 대응하는 1회 복구가 실질적 실행량일 때의 후보다.
- implementation-local 선택이 남은 작업은 Sol Parent에서 Terra Medium 후보이며, Terra Parent는 직접 처리한다.
- benchmark 점수와 비용은 대체로 함께 증가하지만 비례하지 않으며, effort 상승은 Decision Authority를 확장하지 않는다.
- `high`·`xhigh`·`max`는 자동 선택하지 않는다.

---

## 9. 역할별 Decision Authority 및 위임 가능 조건

### 9.1 핵심 판별 질문 (Baseline Requirement)
> **"하위 워커가 이 작업을 수행하려면 내가 이미 완료한 중요한 추론을 다시 해야 하는가?"**

### 9.2 Semantic Decision Closure
Downshift는 미완성된 의미적 판단을 하위 워커에 넘기는 수단이 아니다. 부모는 spawn 전에 결과의 의미, 동작, 범주 및 외부 계약을 확정하고, 하위 워커에는 그 결정을 적용하고 검증하는 실행 판단만 남긴다.

### 9.3 3대 안전성 보조 신호 (Safety Signals)
1. **Coupling (결합도)**: 수정 범위가 국소적이고 영향 범위를 명확히 특정 가능한 작업.
2. **Verification (검증 가능성)**: 테스트, 린트, 타입체크 등 결정적 검증이 가능한 작업.
3. **Consequence (실패 영향도 / Blast Radius)**: 실패 영향이 가역적이고 제한적인 작업 (보안, DB migration, 배포 등은 무조건 부모 직접 수행).

---

## 10. 좋은 위임 작업 예시 (Good Candidates)

### Luna Child 전용 (Implementation Closed)
- 정확한 문자열/문서/docstring 교체
- 부모가 이미 알고리즘과 로직을 결정한 구체적 코드 작성
- 구체적인 acceptance criteria 기반 테스트 작성
- 동일 패턴의 다중 파일 반복 수정 (Rename, 직렬화 필드 교체 등)
- deterministic lint/type 오류 수정

### Terra Child 전용 (Implementation-Local Choice, Sol Parent)
- 외부 API 계약은 확정되었으나 내부 알고리즘(Strategy vs 함수형) 선택이 필요한 작업
- 내부 클래스 구조 및 로컬 자료구조 설계
- 제한된 범위의 로컬 리팩토링 및 탐색이 필요한 구현

---

## 11. 절대 위임하면 안 되는 작업 (Non-Delegable Tasks)

- Gate A 탈락 작업: DB 마이그레이션, 보안/인증 정책, 권한 체계, 배포 작업
- 사용자의 모호한 요구사항을 해석해야 하는 작업
- 원인 규명이 되지 않은 버그를 처음부터 탐색해야 하는 디버깅
- Architecture 및 Public API Contract Trade-off 판단
- 계획 수립(Planning-only), 설명(Explanation-only), 브레인스토밍 요청

---

## 12. 가장 중요한 위임 원칙 (나쁜 예 vs 좋은 예)

부모 모델은 하위 워커에게 **목표만 넘기지 않는다.** 부모가 이미 판단한 내용은 하위 워커가 다시 추론하게 하지 말고 Task Capsule에 명확한 결정 사항으로 담는다.

### 나쁜 예 (Bad)
```text
Improve the readability of UserService.create_user docstring.
```
*문제: 무엇이 읽기 어려운지, 어떤 형식이 맞는지 하위 워커가 다시 판단해야 함.*

### 좋은 예 (Good)

[패키지 내부의 완결된 docstring Capsule](../skills/codex-downshift/references/delegation-examples.md#fixed-docstring-capsule)을 따른다.
고정 대체 문자열·허용 권한·검증·worker 제한을 실제 메시지에 포함하는 예시이며, 스킬 폴더만 설치해도 사용할 수 있다.

---

## 13. Task Capsule 표준 서식 & 4대 Terminal Return Protocols

### 13.1 Task Capsule 핵심 서식

`Apply`는 지정 target 또는 Search 범위 전체의 처리 여부를 정하고, `Delegated authority`는 그 범위 안의 구현 재량을 정한다.
Terra의 implementation-local choice도 `Apply: Exact`와 함께 사용할 수 있다. 고정 결과는 `Rule`과 acceptance에 명시한다.

여러 산출물·all-matches 작업에서 대상별 확인이 필요할 때만 선택적 completion set을 사용한다.
알려진 대상과 범위 내 탐색으로 발견한 대상의 처리 결과(`modified` 또는 근거가 있는 `not modified`) 및 필요한 탐색 근거를 보고한다.
검증 명령이 없더라도 관찰 가능한 확인 절차·통과 기준과 실제 결과가 필요하며, 필요한 검증을 수행하지 못한 상태를 완료로 보고하지 않는다.
상세 서식은 [Task Capsule Template](../skills/codex-downshift/references/task-capsule-template.md)을 따른다.

```text
TASK CAPSULE
Role: You are a leaf worker.
Goal: <명확한 단일 작업 목표>
Scope:
- Search: <검색 대상 경로/심볼; optional>
- Modify: <수정 허용 파일·심볼; optional>
Decisions already made: <부모 모델이 이미 확정한 요구사항, API, 동작 결정>
Delegated authority: <Luna: Predetermined execution / Terra: Implementation-local choice>
Must not decide: <부모 모델 고유의 판단 영역>
Apply: <Exact | All matches within scope>
Rule: <필요한 경우 parent-fixed rule 또는 고정 결과 형식>
Preserve: <유지해야 하는 기존 동작/호환성>
Do not touch: <수정 금지 영역>
Acceptance criteria:
- [ ] <유지해야 할 의미·동작 불변조건>
- [ ] <기계적 검증 결과>
Validation:
- <검증 명령 또는 관찰 가능한 확인 절차·통과 기준 1>
- <검증 명령 또는 관찰 가능한 확인 절차·통과 기준 2>
Recovery policy: At most ONE recovery attempt when appropriate. If recovery is not appropriate or validation still fails, return TASK_FAILED immediately.
Worker constraints: Leaf worker only. Do not spawn or delegate to other agents or models. Do not perform external side-effects or destructive operations. Do not perform destructive git rollbacks. Stop at one of the four terminal return states.
Return protocol: TASK_COMPLETED, TASK_FAILED, NEEDS_PARENT_DECISION, NEEDS_PARENT_ACTION
```

### 13.2 4대 Terminal Return Protocols
1. **`TASK_COMPLETED`**: 다중 Validation 증거와 Acceptance Criteria 대조 결과 반환
2. **`TASK_FAILED`**: 1회 복구 실패 또는 미시도 후 작업트리를 보존하며 실패 블로커 상세 보고 (`Attempted: YES | NO`)
3. **`NEEDS_PARENT_DECISION`**: 새 설계 판단이나 모호성 직면 시 부모에게 제어권 반환
4. **`NEEDS_PARENT_ACTION`**: git push, deploy 등 외부 부수효과 필요 시 부모에게 제어권 반환

---

## 14. Trivial Task Delegation & 작업 단위 정책 (Task Granularity)

1. **배치 위임 원칙 (Batching)**: 서로 관련된 여러 개의 작고 명확한 작업은 하나의 bounded batch 후보로 묶을 수 있다. Gate A를 통과하고 Gate B에서 구현 방법이 확정된 Luna 후보로 판단한 뒤, Economic Gate까지 통과할 때만 Bounded Task Capsule을 작성하여 일괄 위임한다. 조건을 충족하지 못하면 Parent Direct로 처리한다.
2. **Routing signals and Economic Gate**: LOC·파일 수·단일 deterministic validation은 secondary signal이다. 예상 test/fix loop는 leverage 증거지만 자동 위임 명령이 아니다. Gate A → Gate B → Economic Gate를 순서대로 평가하고 Delegation Preparation Test 네 조건을 모두 충족할 때만 위임하며, 아니면 Parent Direct다.
3. **Parent Direct 조건**:
   - trivial literal/mechanical edit는 Delegation Preparation Test가 위임을 정당화하지 않을 때 Parent Direct로 처리할 수 있다. LOC·파일 수 자체가 경로를 독립적으로 결정하지 않는다.
   - 그 밖의 후보도 Delegation Preparation Test를 충족할 때만 위임하고, 아니면 Parent Direct로 처리한다.
4. **경제성 판단의 우선순위**: 안전성·권한·검증 요건을 먼저 충족한다. Parent Usage 절감과 함께 사용자 재지시·재작업·검증을 포함한 [실제 작업 비용](../skills/codex-downshift/references/model-selection.md#실제-작업-비용)을 고려한다. 준비 테스트를 통과해도 위임의 추가 부담이 실행 절감분을 상쇄하면 Parent Direct다.

---

## 15. Parent / Terra Child / Luna Child 책임 분리

| 구분 | Active Parent (Sol/Terra) | Terra Child (Sol Parent) | Luna Child (Sol/Terra) |
| :--- | :--- | :--- | :--- |
| **주요 역할** | 총괄 지휘 및 상위 의사결정 | 로컬 구현 분석 및 선택 | 확정된 기계적 코드 실행 |
| **책임 범위** | 요구사항 해석, 아키텍처, 보안, 최종 검증 | 내부 클래스/알고리즘 구현 | 정형화된 코드 조립, 린트, 테스트 |
| **제약 조건** | 하위 워커 결과 Blind Trust 금지 | Public API 변경 금지, No Chaining | 상위 판단 금지, No Chaining |

---

## 16. TDD 및 개발 워크플로와의 관계

이 Skill은 TDD 자체를 대체하거나 강제하지 않는다. 부모 모델이 TDD를 수행할 때 명확한 단계를 하위 워커에 위임할 수 있다:
- **Parent**: 테스트해야 할 동작과 테스트 케이스 결정
- **Luna**: 정확히 정의된 실패 테스트 작성 및 실행
- **Parent**: 결과 검토 및 다음 구현 방향 확정
- **Luna/Terra**: 결정된 구현 수행 및 테스트 실행

---

## 17. Superpowers 생태계와의 관계

이 Skill은 Superpowers(`writing-skills`, `verification-before-completion`, `subagent-driven-development`)와 독립적이면서도 실용적으로 정합되어 동작한다.
- Superpowers가 planning, TDD, debugging 워크플로를 주도하더라도, 부모가 구체적으로 결정한 실행 작업을 안전하게 하향 위임하는 목적은 동일하게 유지된다.

---

## 18. Evidence Before Completion & Scope Matching

Parent는 Child의 성공 보고를 무조건 신뢰(Blind Trust)하지 않으며 다음 원칙을 준수한다:
- **`Verification scope MUST match the completion claim scope.`**
- Parent가 사용자에게 보고하려는 claim 범위에 정확히 비례하는 **Minimum Sufficient Fresh Verification을 직접 수행**한다.

---

## 19. Non-Goals

- 범용 AI model router나 임의 switching을 구현하지 않는다.
- 상향 에스컬레이션(`Luna/Terra ➔ Sol`)이나 동일 티어 재위임을 구현하지 않는다.
- 별도의 daemon, config 시스템, runtime wrapper를 추가하지 않는다.
- `high`/`xhigh`/`max` reasoning effort를 자동 spawn에 사용하지 않는다.

---

## 20. 성공 기준 (Success Criteria)

### 기능적 성공 기준
- Sol/Terra에서 명확한 실행 작업이 하위 워커로 안전하게 위임된다.
- Gate A에서 High Consequence 작업이 완벽히 차단된다.
- 하위 워커가 다른 에이전트를 생성하지 않는다 (No Chaining).
- 부모 모델이 최종 판단권을 온전히 유지한다.

### 실사용 성공 기준
- Sol/Terra 사용량이 유의미하게 감소한다.
- 위임으로 인한 불필요한 재작업이 최소화된다.
- 품질 저하 없이 결과물의 완성도가 유지된다.

---

## 21. 배포 및 설치 경로 정책

수동 설치와 skills CLI 설치의 경로를 구분한다. [README 설치 안내](../README.md#설치)를 설치 정보의 기준으로 사용한다.
공식 사용자 탐색 경로와 CLI의 agent별 전역 경로가 다를 수 있으며, 경로 이름만으로 에이전트 간 격리를 보장하지 않는다.

- **표준 CLI 설치**:
  ```bash
  npx skills@latest add callorange/codex-downshift --skill codex-downshift --agent codex --global
  ```

---

## 22. Acknowledgements & References

Parts of the delegation safety design and execution constraints were inspired by [codex-auto-model-router](https://github.com/orange-the-weak/codex-auto-model-router), particularly its bounded task delegation, task capsule structure, validation budget, and fail-safe execution concepts. `codex-downshift` was independently redesigned and implemented to serve as a lightweight, instruction-only skill focusing strictly on Parent-controlled downshifting with Tiered Downshift and Gate A → Gate B → Economic Gate.

---

## 23. 한 문장 정의

> **Keep the user's Sol or Terra parent in control, and offload bounded execution work to Luna & Terra.**

한국어:
> **사용자가 선택한 Sol 또는 Terra의 판단권은 유지하고, Gate A → Gate B → Economic Gate를 통과한 실행 작업만 Luna 또는 Terra에 안전하게 하향 위임한다.**
