---
name: codex-downshift
description: Use when operating as an Active Parent model (Sol or Terra) on bounded implementation work where requirements or external contracts are clear. Evaluates safe and economical delegation to a lower model tier or the same model at a lower reasoning effort while preserving Parent Direct when delegation overhead is not worthwhile.
---

# Codex Downshift (Execution Delegator Skill)

본 스킬은 OpenAI Codex 환경에서 부모 모델(**Sol** 또는 **Terra**)이 상위 판단을 완료한 후, 안전 게이트와 남은 판단 권한(Decision Authority)에 따라 구체적인 실행 작업을 더 낮은 모델 tier 또는 같은 모델의 더 낮은 reasoning effort를 사용하는 Leaf Child로 다운시프트하여 Codex 사용량과 반복 비용을 절감하는 실행 지침입니다.

---

## 🎯 1. 핵심 철학 및 10대 불변 규칙 (10 Core Invariants)

> **"Safe enough to delegate → delegate only the remaining authority → keep every child leaf-only → return structured evidence → let the Parent make only claims it freshly verified."**

### 1. Parent Authority (부모 모델 권한 보존)

사용자가 선택한 Active Parent(Sol 또는 Terra)는 요구사항 해석, 제품 동작, 아키텍처, Public API, 보안, 호환성 등 모든 상위 미결 판단을 직접 소유한다. Parent 역할 자체는 Child에게 위임되지 않는다.

### 2. Downshift Only (구성 기준 단방향 하향 위임)

Child 구성은 Active Parent보다 다음 중 한 방식으로 엄격히 낮아야 한다.

- **모델 하향**: `Sol ➔ Terra/Luna`, `Terra ➔ Luna`. 하위 모델의 effort는 별도 effort 정책과 작업 적합성을 따른다.
- **effort 하향**: 같은 모델에서 `Light < Medium < High < XHigh < Max` 순서상 Parent보다 낮은 effort를 명시한다.
- **금지**: 상위 모델 호출, 같은 모델의 동일·상위 effort, 실제 Parent model/effort를 추정한 같은 모델 위임.
- **자동 경로**: Child target effort는 Light 또는 Medium만 사용한다. `high`·`xhigh`·`max` target은 사용자 명시적 요청·승인이 있는 예외다.
- *(단, Child가 `NEEDS_PARENT_*` 또는 `TASK_FAILED`로 Parent에게 제어권을 반환하는 것은 상향 위임이 아니며 정상 프로토콜임)*

### 3. Safety Before Routing (Gate A)

모델 선택 전에 반드시 **Gate A (Delegation Safety Gate)**를 먼저 통과해야 한다. 저위험·가역적·검증 가능한 작업이 아니면 모델 판단 없이 무조건 **Parent Direct**.

### 4. Role-Based Child Delegated Authority (역할별 위임 권한)

- **Luna Child**:
  - **필수 상태**: `Semantic Closed` + `External Contract Closed` + `Implementation Closed`.
  - **위임 권한**: 구현 패턴과 방법까지 확정된 기계적 실행 전담.
  - **검색 범위**: Parent가 `all matches`를 요구하면 검색 범위 전체를 exhaustive하게 확인하며, non-exhaustive examples를 전체 목록으로 오인하지 않는다.
  - **판단 필요 시**: Match가 정책/의미 판단을 요구하면 `NEEDS_PARENT_DECISION`으로 반환한다.
- **Terra Child**:
  - **필수 상태**: `Semantic Closed` + `External Contract Closed` + `Implementation-Local Decision Remains`.
  - **위임 권한**: 외부 계약 안의 내부 구현 분석 및 선택. Sol Parent의 모델 하향 또는 더 높은 effort의 Terra Parent가 수행하는 effort 하향에서 사용한다.
- **Sol Child**:
  - **필수 상태**: `Semantic Closed` + `External Contract Closed` + bounded implementation work이며 Active Parent가 더 높은 effort의 Sol이다.
  - **위임 권한**: Sol tier가 필요한 관계·정합성 실행을 Parent보다 낮은 effort로 수행한다. 제품·아키텍처·보안·Public API의 미결 판단은 받지 않는다.

### 5. Leaf Worker / No Chaining

모든 Child는 Leaf Worker이며 다른 agent나 model을 spawn/invoke/delegate할 수 없다. `Sol ➔ Terra ➔ Luna` 다단계 체이닝 금지.

### 6. Fail Closed

Child spawn 실패, 라우팅 모호성, 또는 권한 불확실 시 다른 하위 모델로 우회하지 않고 **부모 모델이 직접 수행**.

### 7. Reasoning Effort & 모델 정책

- **Luna**: 기본값 Light (`reasoning_effort = "low"`). 구현이 닫힌 상태에서 bounded search 또는 검증 실패를 해석해 Parent가 고정한 Rule로 대응하는 1회 복구가 실행의 실질적 부분이면 Medium (`reasoning_effort = "medium"`)을 후보로 삼는다. effort 상승은 구현 판단 권한을 확장하지 않는다.
- **Terra**: 일반 implementation-local 작업은 Medium, 기존 패턴으로 선택지가 좁고 결정적 검증이 가능한 작업은 Light를 후보로 삼는다.
- **같은 모델 effort 하향**:
  - Terra Parent: implementation-local 선택 때문에 Luna 권한을 넘고 낮은 Terra effort가 충분할 때 후보로 삼는다.
  - Sol Parent: 상호 의존 관계나 독립 요구사항을 함께 추적하고, 결정적 검증만으로 누락 확인이 어려워 Terra가 Parent 수동 검증·재작업을 늘릴 때 후보로 삼는다.
  - 두 경로 모두 같은 모델 유지 자체는 근거가 아니다.
- **자동 선택 금지**: `high` / `xhigh` / `max`는 자동 선택 절대 금지 (사용자 명시적 요청/승인 시에만 예외 허용).
- *(수치 근거는 [Model Economics](references/model-economics.md), 성능 관측은 [Model Benchmarks](references/model-benchmarks.md), 종합 추천은 [Model Selection Guide](references/model-selection.md) 참조)*

### 8. Max 1 Recovery

Child validation 실패 시 자체 구현 수정은 가능한 경우에 한해 최대 1회만 허용(환경/의존성 등 부적절한 경우 미시도). 재실행 실패 또는 미시도 시 즉시 `TASK_FAILED`로 중단.

### 9. Structured Return Protocols

Child는 반드시 4대 반환 프로토콜(`TASK_COMPLETED`, `TASK_FAILED`, `NEEDS_PARENT_DECISION`, `NEEDS_PARENT_ACTION`) 중 하나로 종료하며, 임의로 destructive rollback(`git reset --hard` 등)을 수행하지 않음.

### 10. Evidence Before Completion (Scope Matching)

Parent는 Child 결과를 Blind Trust하지 않으며, **자신이 하려는 Completion Claim의 범위와 정확히 일치하는 Minimum Sufficient Fresh Verification을 직접 수행**.

---

## 🛑 The Parent Execution Protocol (4단계 다운시프트 루프)

Parent는 소스 코드 편집 도구(`write_to_file`, `replace_file_content` 등)를 직접 호출하기 전에 **반드시** 아래 1단계의 게이트 평가를 수행해야 합니다. 게이트 결과가 Child delegation이면 2–4단계를 이어서 수행하고, Parent Direct이면 정상적으로 short-circuit합니다:

### 1. Trigger & Gate Check

- **Active Configuration Resolution (hard precondition, not a new gate)**:
  - **모델 확인**: Child를 선택하기 전에 현재 session/runtime 정보로 실제 Active Parent model을 확인한다. task complexity, 이전 turn, default 또는 repository context로 추정하지 않는다.
  - **effort 확인**: 같은 모델의 effort 하향을 선택하려면 실제 Parent effort도 확인한다. effort를 확인할 수 없으면 같은 모델 Child는 ineligible이며, 확인된 model을 기준으로 하위 모델 후보만 평가한다.
  - **엄격한 하향 확인**: 같은 모델 Child의 target effort가 Parent보다 낮지 않거나 비교할 수 없으면 Parent Direct로 fail closed한다.
- [선행 조건] 상위 요구사항/아키텍처/보안 판단이 Parent에 의해 완료되었는가? (미완료 시 Parent Direct로 추론 완료 우선)
- [보조 신호] LOC·파일 수는 약한 secondary signal일 뿐이며 Parent Direct 또는 delegation을 독립적으로 결정하지 않는다. 작업 속성(사소한 literal/mechanical edit, fixed-rule bounded execution, bounded search, 예상 test/fix loop, implementation-local decision, high-consequence/irreversible work)을 관찰한다.
- ➔ Gate A(안전성) → Gate B(잔여 권한/후보 선택) → Economic Gate 순으로 평가한다.
- **Parent Direct**: Gate A, Gate B, 또는 Economic Gate가 Parent Direct를 선택하면 delegation 목적의 Task Capsule을 작성하지 않고 Child를 spawn하지 않는다. Parent가 직접 구현하고 직접 검증한다.
- **Child delegation**: 위임이 선택된 경우에만 다음 단계를 수행한다.

### 2. Capsule Emission

- [Task Capsule 표준 서식](references/task-capsule-template.md)에 따라 목표, 허용 범위, Acceptance Criteria, 검증 명령을 확정하여 프롬프트 작성.

### 3. Leaf Worker Spawn

- `spawn_agent`에 Gate에서 선택한 Child 모델과 effort를 그대로 전달한다 (`fork_turns = "none"`). 자동 target effort는 Light의 `low` 또는 Medium의 `medium`이다.
- *부모 세션 모델을 상속(`inherit`)하거나 모델 파라미터를 생략하는 것은 금지.*

### 4. Collect & Scope-Matched Verify

- 워커의 반환(`TASK_COMPLETED`) 수신 후, Parent가 `git diff` 확인 및 자신의 완료 주장에 부합하는 최소 단위 검증을 직접 실행.

---

## 🧭 2. 게이트 기반 결정적 라우팅 파이프라인 (Routing Pipeline)

```text
Active Configuration Resolution (hard precondition, not a new gate)
  │ actual Parent model 확인; effort-only 후보는 actual effort도 확인
  ├─ model 확인 ──────────────────────────────────────────→ lower-model 후보 평가 가능
  ├─ model + effort 확인 ─────────────────────────────────→ same-model lower-effort 후보 평가 가능
  └─ model 확인 불가 ─────────────────────────────────────→ Parent Direct
  │
Active Parent (confirmed Sol or Terra)
  │
  ├─ 1. 상위 판단 미결 (Semantic / Architecture / Security)?
  │    YES ──────────────────────────────────────────→ Parent Direct (상위 추론/판단 직접 수행)
  │    NO (상위 판단 완료)
  ▼
  ├─ 2. 작업 크기/검증 패턴은 보조 참조만 사용
  │    └─ 단일 deterministic validation은 강제 trigger가 아님
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
│ Gate B: Decision Authority & Capability Fit               │
│ - closed mechanical execution ─────────────→ Luna Light  │
│ - closed bounded search/fixed recovery ────→ Luna Medium │
│ - narrow established local choice ─────────→ Terra Light │
│ - general implementation-local choice ─────→ Terra Medium│
│ - lower tier raises rework/verification cost              │
│   ───────────────→ same-model strictly lower Light/Medium │
│ - no eligible strictly lower configuration ─→ Parent Direct│
└──────────────────────────────────────────────────────────┘
                             │ candidate selected
                             ▼
┌──────────────────────────────────────────────────────────┐
│ Economic Gate: Delegation Preparation Test                │
│ Four preparation conditions pass AND net benefit remains │
│ → selected Child; otherwise → Parent Direct              │
└──────────────────────────────────────────────────────────┘
```

### 🚀 Routing Signals and Economic Gate

작업 속성이 라우팅의 주 기준이다. 아래 후보는 Gate A를 통과한 경우에 한하며, 실제 위임은 Economic Gate까지 통과해야 한다.

| 관찰한 작업 속성 | 라우팅에서의 의미 |
| --- | --- |
| trivial literal/mechanical edit | Parent Direct 후보 |
| fixed-rule bounded execution | Luna 후보 |
| bounded search 또는 예상 test/fix loop | 경제성 평가 신호 |
| implementation-local decision | Terra Light/Medium 후보. Terra Parent에서는 target effort가 실제 Parent보다 낮아야 한다. |
| implementation-local 선택 때문에 Luna의 위임 권한을 넘음 | Terra Light/Medium 후보를 비교한다. Terra Parent라면 같은 모델의 엄격히 낮은 effort만 허용한다. |
| 상호 의존하는 규칙·문서·계약 또는 독립 요구사항을 함께 추적해야 하고, 결정적 검증만으로 누락을 확인하기 어려움 | Sol Parent에서는 더 낮은 Sol Light/Medium과 Terra 후보의 준비·재작업·검증 부담을 비교한다. |
| high-consequence/irreversible work | Parent Direct |

LOC·파일 수는 약한 secondary signal로만 참고한다.

> [!NOTE]
> Gate A는 안전성, Gate B는 권한별 후보, Economic Gate는 아래 Delegation Preparation Test를 적용한다. 근거 미확정의 운영 가설은 라우팅 기준으로 사용하지 않는다.

단일 결정적 검증만 필요한 작업은 위임 트리거가 아니다. 반대로 테스트-수정 루프가 예상되면 실행량이 커져 경제성 평가 가치가 높다. LOC는 보조 지표일 뿐이다.

### 💰 Economic Gate and Delegation Preparation Test

경제성은 Delegation Preparation Test로 판단한다. 이를 통과해도 위임의 추가 재지시·재작업·검증 부담이 실행 절감분을 상쇄하면 Parent Direct다. 공식 요율과 Estimated Consumption Index의 수치·해석 범위는 [Model Economics](references/model-economics.md)를 따른다.

**Delegation Preparation Test**

다음 네 조건에 모두 해당할 때만 위임한다:

1. Parent가 goal, scope, fixed decisions, acceptance를 이미 알고 있는가;
2. Child task 준비에 direct execution과 비교 가능한 분석이 필요하지 않은가;
3. Child가 의미 있는 bounded search, 반복, 구현 또는 test/fix work를 대체하는가;
4. Parent preparation plus verification이 대체되는 execution보다 명확히 작은가.

**불충족 시**: 하나라도 아니면 Parent Direct다.

### 📚 On-demand references

Core rules로 결정되면 모든 reference를 preload하지 않는다.

| 참조 문서 | 읽는 조건 |
| --- | --- |
| `task-capsule-template.md` | 실제 Child delegation을 선택하고 Capsule을 작성할 때만 읽는다. |
| `model-economics.md` | Economic Gate에서 공식 요율·추정 지수·비용 모델이 필요할 때만 읽는다. |
| `model-benchmarks.md` | 모델·effort별 외부 성능 관측이나 그 한계를 비교할 때만 읽는다. |
| `model-selection.md` | Parent 설정 또는 기존 Child 후보의 effort 추천이 필요할 때만 읽는다. |
| `delegation-examples.md` | core rules로 routing 사례가 여전히 모호할 때만 읽는다. |
| `terminal-scenarios.md` | terminal state, recovery, exceptional effort 또는 Parent verification 사례가 필요할 때만 읽는다. |

### 👁️ Routing Notice

Active Configuration Resolution → Gate A → Gate B → Economic Gate routing 평가를 실제로 수행한 경우에만, 최종 routing 결정을 사용자에게 정확히 한 번 표시한다.

| 상황 | 출력 시점·횟수 | 표시 내용과 제한 |
| --- | --- | --- |
| Child delegation 선택 | 실제 spawn 직전 한 번 | 아래 Child 형식 사용. `<model>`은 현재 Parent가 아니라 실제 spawn할 Child model이다. |
| Parent Direct 선택 | 최종 결정 시 한 번; Child spawn 불필요 | 아래 Parent Direct 형식 사용. Gate A, Gate B 또는 Economic Gate 중 최종 결정을 만든 첫 번째 결정적 이유만 짧게 담는다. |
| 스킬이 적용되지 않아 routing 평가를 수행하지 않음 | 출력하지 않음 | routing notice 없음 |
| Child spawn 실패 | 추가 routing notice 없음 | Fail-Closed 규칙에 따라 Parent가 직접 수행한다. |

**Child 형식**

`[codex-downshift] → <model> (<effort>) | <task_name> | <brief reason>`

**Parent Direct 형식**

`[codex-downshift] → Parent Direct | <task_name> | <first decisive gate or brief reason>`

Parent Direct notice에 모든 gate 평가나 상세 추론을 나열하지 않는다. 전체 capsule은 출력하지 않는다.

### Micro-batching

**묶을 수 있는 조건**

다음 조건을 모두 충족하면 하나의 micro-batch 후보로 묶을 수 있다:

- 서로 독립적인 복수의 저위험·가역적·Implementation-Closed 항목이다.
- 같은 Luna model/effort와 bounded scope를 공유한다.
- 의존성·아키텍처·제품·보안·Public API에 관한 미결 판단이 없다.
- 각 항목을 별도로 위임하는 것보다 하나의 Capsule로 묶는 준비·조율·결과 확인 부담이 작다.

실제 위임은 Gate A → Gate B → Economic Gate를 모두 통과할 때만 수행한다.
묶음 처리가 별도 위임보다 저렴하더라도 Parent Direct보다 경제적이라는 뜻은 아니다.

**결과·판단 필요 시 처리**

각 항목의 checkmark 결과를 반환하고 하나라도 판단이 필요하면 네 terminal state를 보존하며 worktree를 명확히 보고한다.

**구별할 작업**

이는 하나의 고정 규칙을 반복 적용하는 pattern batch와 구별한다.

### Profile semantics

아래는 Gate A를 통과한 작업의 후보이며, 실제 위임은 Economic Gate까지 통과해야 한다.

| 후보 | 필요한 상태 | 허용되는 구현 재량 | Parent 제한 |
| --- | --- | --- | --- |
| Luna Light | Implementation Closed + target locations closed | 확정된 구현을 지정 위치에 적용 | Sol 또는 Terra Parent |
| Luna Medium | Implementation Closed + Match Rule Closed + bounded search 또는 검증 실패에 고정 Rule로 대응하는 1회 복구 필요 | 고정 Rule로 탐색·적용·검증·복구; 구현 판단 권한 확대 없음 | Sol 또는 Terra Parent |
| Terra Light | 의미·외부 계약 확정 + 기존 패턴으로 선택지가 좁은 implementation-local 작업 | 고정 계약과 기존 패턴 안의 좁은 구현 선택 | Sol Parent 또는 effort가 Light보다 높은 Terra Parent |
| Terra Medium | 의미·외부 계약 확정 + 일반 implementation-local 선택 잔여 | 고정 외부 계약 안의 내부 구현 분석·선택 | Sol Parent 또는 effort가 Medium보다 높은 Terra Parent |
| Sol Light | 의미·외부 계약 확정 + 상호 의존하는 관계 또는 독립 요구사항을 함께 추적하는 bounded 실행 | 관계·정합성 실행과 고정 계약 안의 구현 선택 | effort가 Light보다 높은 Sol Parent; 결정적 검증만으로 누락 확인이 어려워 Terra 사용 시 Parent 수동 검증·재작업이 늘어나는 근거 필요 |
| Sol Medium | 의미·외부 계약 확정 + 상호 의존하는 관계 또는 독립 요구사항을 함께 추적하는 bounded 실행 | 관계·정합성 실행과 고정 계약 안의 구현 선택 | effort가 Medium보다 높은 Sol Parent; 결정적 검증만으로 누락 확인이 어려워 Terra 사용 시 Parent 수동 검증·재작업이 늘어나는 근거 필요 |

**Luna 공통 경계**

Luna는 Match Rule을 만들거나 넓히지 않으며, all-matches는 named/example 첫 발생에서 멈추지 않고 Search 경계 전체에 고정 Rule을 적용한다.
semantic/architecture/product/compatibility/policy 판단이 필요하면 `NEEDS_PARENT_DECISION`이다.

**Terra와 Sol effort-only Child에 전달할 계약**

공통 Scope·Apply·검증·worker 제한·반환 계약을 유지하면서, implementation-local 재량이 있는 Child에는 다음을 제공하고 절차를 과도하게 지정하지 않는다:

- goal
- fixed external contract
- forbidden changes
- acceptance
- local criteria(기존 패턴 선호, 최소 구현, Public API 보존)

### 🔍 Parent Direct 조건

- high-consequence/irreversible work는 Gate A에서 Parent Direct로 처리한다.
- 저위험·가역적인 trivial literal/mechanical edit는 작업 종류만으로 직접 수행을 확정하지 않는다. Gate A를 통과하면 Gate B에서 후보를 선정하고, Economic Gate의 Delegation Preparation Test를 충족하지 못하면 Parent Direct로 처리한다.
- LOC·파일 수만으로 경로를 결정하지 않는다.
- 같은 모델의 더 낮은 effort가 확인되지 않거나 하위 tier보다 나은 capability-fit 근거가 없으면 effort-only Child를 선택하지 않는다.

---

## 🚀 3. Spawn and Return Contract

자동 경로에서는 부모 속성을 상속하지 않도록 `model`, `fork_turns = "none"`, `reasoning_effort`, `task_name`, `message`를 모두 명시한다. `message`는 [Task Capsule Template](references/task-capsule-template.md)의 Minimum Sufficient Context로 작성한다.

| 경로 | 추가 구성 조건 | `model` | 자동 `reasoning_effort` |
| --- | --- | --- | --- |
| Sol 또는 Terra Parent → Luna Light | model 하향 | `gpt-5.6-luna` | `low` |
| Sol 또는 Terra Parent → Luna Medium | model 하향 | `gpt-5.6-luna` | `medium` |
| Sol Parent → Terra Light | model 하향 | `gpt-5.6-terra` | `low` |
| Sol Parent → Terra Medium | model 하향 | `gpt-5.6-terra` | `medium` |
| Terra Parent → Terra Light | 실제 Parent effort가 Medium 이상 | `gpt-5.6-terra` | `low` |
| Terra Parent → Terra Medium | 실제 Parent effort가 High 이상 | `gpt-5.6-terra` | `medium` |
| Sol Parent → Sol Light | 실제 Parent effort가 Medium 이상 | `gpt-5.6-sol` | `low` |
| Sol Parent → Sol Medium | 실제 Parent effort가 High 이상 | `gpt-5.6-sol` | `medium` |

하위 모델 경로에는 Parent와 Child의 effort 비교를 적용하지 않는다. 같은 모델 경로는 실제 Parent effort를 확인하고 target보다 엄격히 높은 경우에만 허용한다.

`high`·`xhigh`·`max` exceptional override도 명시적 사용자 요청·승인과 모든 gate를 충족해야 하며, 모델 권한·Leaf Worker·복구 한도는 바뀌지 않는다.

### Terminal Return Protocol

모든 Child 작업은 반드시 다음 4가지 상태 중 하나로 종료해야 합니다. Child는 자의적인 rollback(`git reset --hard` 등)을 하지 않고 현재 상태를 보존하여 보고합니다.

| 반환 상태 | 반환 조건 | 필요한 보고·후속 동작 |
| --- | --- | --- |
| `TASK_COMPLETED` | Acceptance criteria 충족 및 검증 통과 | 완료 기준 대조와 검증 증거 보고 |
| `TASK_FAILED` | 1회 복구 실패 또는 복구 미시도 | 작업트리 보존, 실패 원인 및 복구 시도 여부·미시도 사유 상세 보고 |
| `NEEDS_PARENT_DECISION` | 위임 범위를 넘는 새로운 설계/동작 판단 필요 | 미결 판단과 위임 권한을 넘는 이유를 보고하고 Parent에게 제어권 반환 |
| `NEEDS_PARENT_ACTION` | `git push`, `deploy`, 비밀값 등 외부 권한 작업 필요 | 필요한 외부 작업과 그 전까지 완료한 작업을 보고하고 Parent에게 제어권 반환 |

상세 반환 필드는 [Task Capsule Template](references/task-capsule-template.md), 판단·실패·복구 사례는 [Terminal & Recovery Scenarios](references/terminal-scenarios.md)를 따른다.

---

## 🔍 4. Parent Evidence Before Completion & Scope Matching

Parent는 Child의 성공 보고를 Blind Trust하지 않고 다음 순서로 완료를 확정합니다:
1. `git diff` 및 수정 파일 목록 검토.
2. Task Capsule의 Acceptance 충족 여부 확인. Completion set을 사용했다면 대상별 처리 결과와 필요한 검색 완료 근거도 확인한다.
   검증은 명령 또는 관찰 가능한 확인 절차와 실제 결과로 뒷받침하며, 필요한 검증을 수행하지 못했다면 완료로 보고하지 않는다.
3. **Claim-Verification Scope Matching**:
   - **원칙**: `Verification scope MUST match the completion claim scope.`
   - Parent가 사용자에게 보고하려는 완료 범위에 정확히 비례하는 **Minimum Sufficient Fresh Verification을 직접 실행**.
   - *(예: 특정 회귀 버그 claim ➔ 해당 단위 테스트 직접 실행)*.

## 📚 5. 참조 문서

- [Model Economics & Estimated Consumption Index](references/model-economics.md)
- [Model Benchmarks](references/model-benchmarks.md)
- [Model Selection Guide](references/model-selection.md)
- [위임 라우팅 사례](references/delegation-examples.md)
- [Terminal & Recovery Scenarios](references/terminal-scenarios.md)
- [Task Capsule 및 4대 반환 프로토콜 표준 서식](references/task-capsule-template.md)
- [프로젝트 상세 기획 명세서 — 저장소 참고 자료](https://github.com/callorange/codex-downshift/blob/main/docs/codex-downshift-spec.md)
