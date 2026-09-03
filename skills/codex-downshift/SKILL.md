---
name: codex-downshift
description: Use whenever operating as an Active Parent model (Sol or Terra) and about to implement, modify, refactor, or test code for a bounded task where requirements or external contracts are clear. Enforces offloading execution to lower-tier leaf workers (Luna or Terra) instead of directly editing code in the Parent session.
---

# Codex Downshift (Execution Delegator Skill)

본 스킬은 OpenAI Codex 환경에서 상위 부모 모델(**Sol** 또는 **Terra**)이 상위 판단을 완료한 후, 사전에 검증된 안전 게이트와 남은 판단 권한(Decision Authority)에 따라 구체적인 실행 작업을 **Luna** (`gpt-5.6-luna`) 또는 **Terra** (`gpt-5.6-terra`) 자식 워커로 다운시프트(하향 위임)하여 Codex 사용량과 반복 비용을 절감하는 실행 지침입니다.

---

## 🎯 1. 핵심 철학 및 10대 불변 규칙 (10 Core Invariants)

> **"Safe enough to delegate → delegate only the remaining authority → keep every child leaf-only → return structured evidence → let the Parent make only claims it freshly verified."**

1. **Parent Authority (부모 모델 권한 보존)**: 사용자가 선택한 Active Parent(Sol 또는 Terra)는 요구사항 해석, 제품 동작, 아키텍처, Public API, 보안, 호환성 등 모든 상위 미결 판단을 직접 소유한다. Parent 역할 자체는 Child에게 위임되지 않는다.
2. **Downshift Only (단방향 하향 위임)**: Child는 Active Parent보다 동일하거나 높은 tier의 모델을 새로 spawn/invoke할 수 없다.
   - **허용**: `Sol Parent ➔ Terra Child`, `Sol Parent ➔ Luna Child`, `Terra Parent ➔ Luna Child`
   - **금지**: `Sol Parent ➔ Sol Child`, `Terra Parent ➔ Terra Child`, `Terra Child ➔ Sol`, `Luna Child ➔ Terra/Sol`
   - *(단, Child가 `NEEDS_PARENT_*` 또는 `TASK_FAILED`로 Parent에게 제어권을 반환하는 것은 상향 위임이 아니며 정상 프로토콜임)*
3. **Safety Before Routing (2단계 게이트)**: 모델 선택 전에 반드시 **Gate A (Delegation Safety Gate)**를 먼저 통과해야 한다. 저위험·가역적·검증 가능한 작업이 아니면 모델 판단 없이 무조건 **Parent Direct**.
4. **Role-Based Child Delegated Authority (역할별 위임 권한)**:
   - **Luna Child**: `Semantic Closed` + `External Contract Closed` + `Implementation Closed`. 구현 패턴과 방법까지 확정된 기계적 실행 전담.
   - **Terra Child**: `Semantic Closed` + `External Contract Closed` + `Implementation-Local Decision Remains`. 외부 계약은 확정되었으나 내부 구현 분석 및 선택이 필요한 경우 전담 (Sol Parent 전용).
5. **Leaf Worker / No Chaining**: 모든 Child는 Leaf Worker이며 다른 agent나 model을 spawn/invoke/delegate할 수 없다. `Sol ➔ Terra ➔ Luna` 다단계 체이닝 금지.
6. **Fail Closed**: Child spawn 실패, 라우팅 모호성, 또는 권한 불확실 시 다른 하위 모델로 우회하지 않고 **부모 모델이 직접 수행**.
7. **Reasoning Effort Policy (No automatic above medium & Luna Light Default)**:
   - **Luna**: 기본값 `light` (1.00× 최적 효율). `medium` 이상 지정 시 토큰 급증(Luna Medium 3.54× > Terra Medium 2.46×)으로 비효율.
   - **Terra**: `light` (1.84×) 또는 `medium` (2.46×) 허용 (기본값: `light`).
   - `high` / `xhigh` / `max`: 자동 선택 절대 금지 (Luna High 10.45× > Sol High 8.61×로 비용 역전 발생).
   - *Reasoning effort 상승은 사고 깊이만 늘릴 뿐 위임된 판단 권한(Decision Authority)을 확장하지 않음.*
8. **Max 1 Recovery**: Child validation 실패 시 자체 구현 수정은 가능한 경우에 한해 최대 1회만 허용(환경/의존성 등 부적절한 경우 미시도). 재실행 실패 또는 미시도 시 즉시 `TASK_FAILED`로 중단.
9. **Structured Return Protocols**: Child는 반드시 4대 반환 프로토콜(`TASK_COMPLETED`, `TASK_FAILED`, `NEEDS_PARENT_DECISION`, `NEEDS_PARENT_ACTION`) 중 하나로 종료하며, 임의로 destructive rollback(`git reset --hard` 등)을 수행하지 않음.
10. **Evidence Before Completion (Scope Matching)**: Parent는 Child 결과를 Blind Trust하지 않으며, **자신이 하려는 Completion Claim의 범위와 정확히 일치하는 Minimum Sufficient Fresh Verification을 직접 수행**.

---

## 🛑 The Parent Execution Protocol (4단계 다운시프트 루프)

Parent는 소스 코드 편집 도구(`write_to_file`, `replace_file_content` 등)를 직접 호출하기 전에 **반드시** 아래 4단계를 순서대로 수행해야 합니다:

1. **Trigger & Gate Check**: 
   - [선행 조건] 상위 요구사항/아키텍처/보안 판단이 Parent에 의해 완료되었는가? (미완료 시 Parent Direct로 추론 완료 우선)
   - [호출 기준] 10줄 이상, 테스트 루프 수반, 또는 다중 파일인가? (손익분기점 충족 확인)
   - ➔ 충족 시 Gate A(안전성) 통과 확인 후 Gate B(잔여 권한)로 워커 모델 결정 (`gpt-5.6-luna` vs `gpt-5.6-terra`).
2. **Capsule Emission**: 
   - [Task Capsule 표준 서식](references/task-capsule-template.md)에 따라 목표, 허용 범위, Acceptance Criteria, 검증 명령을 확정하여 프롬프트 작성.
3. **Leaf Worker Spawn**: 
   - `spawn_agent`로 하위 모델을 명시하여 디스패치 (`fork_turns = "none"`, Luna는 `reasoning_effort = "low"` [Light 1.00×]).
   - *부모 세션 모델을 상속(`inherit`)하거나 모델 파라미터를 생략하는 것은 금지.*
4. **Collect & Scope-Matched Verify**: 
   - 워커의 반환(`TASK_COMPLETED`) 수신 후, Parent가 `git diff` 확인 및 자신의 완료 주장에 부합하는 최소 단위 검증을 직접 실행.

---

## 🧭 2. 2단계 결정적 라우팅 파이프라인 (Routing Pipeline)

```text
Active Parent (Sol or Terra)
  │
  ├─ 1. 상위 판단 미결 (Semantic / Architecture / Security)?
  │    YES ──────────────────────────────────────────→ Parent Direct (상위 추론/판단 직접 수행)
  │    NO (상위 판단 완료)
  ▼
  ├─ 2. 다운시프트 손익분기점(BEP) 미달 (≤3줄 오타/상수 단발 수정)?
  │    YES ──────────────────────────────────────────→ Parent Direct (오버헤드 방지)
  │    NO (10줄 이상, 테스트 사이클, 다중 파일 등 BEP 충족)
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
│ ├─ Semantic 닫힘 + Implementation-local 분석/선택 남음    │
│ │  ─────────────────────────────────────────→ Terra Child│
│ └─ Implementation까지 닫힌 기계적 조립/테스트              │
│    ──────────────────────────→ Luna Child (low [1.00×])  │
│                                                          │
│ (Active Terra Parent)                                    │
│ ├─ Implementation까지 닫힌 기계적 조립/테스트              │
│ │  ──────────────────────────→ Luna Child (low [1.00×])  │
│ └─ 그 외 로컬 구현 작업                                  │
│    ─────────────────────────────────────────→ Terra Direct│
└──────────────────────────────────────────────────────────┘
```

### 🚀 Downshift Mandatory Trigger Criteria (즉시 호출 기준: 손익분기점)

Parent가 상위 추론을 완료한 실행 작업 중, 다음 3가지 조건 중 **어느 하나라도 해당하면** 다운시프트가 무조건 이득이 되는 손익분기점(BEP)을 초과한 상태입니다. Parent는 즉시 직접 수정을 중단하고 하위 워커를 호출(spawn)해야 합니다:

1. **테스트/검증 사이클 (Test & Validation Loop)**:
   - 단위 테스트 코드를 작성해야 하거나, 수정 후 테스트 명령어(`pytest`, `npm test` 등)를 실행하여 결과를 확인·수정해야 하는 모든 작업.
   - *(테스트-수정 반복 턴은 메인 세션 컨텍스트를 급격히 오염시키므로 무조건 위임)*
2. **코드 규모 (Scale Threshold: 10줄 이상)**:
   - 새로 작성하거나 변경할 코드가 **10줄 이상**(또는 함수/클래스 1개 단위)인 작업.
   - *(10줄 이상의 코딩은 Task Capsule 작성 오버헤드를 상쇄하고도 남음)*
3. **다중 파일 범위 (Multi-File Scope)**:
   - 수정 대상이 **2개 이상의 파일**에 걸쳐 있는 작업.
   - *(개별 파일마다 직접 수정하지 않고 1개의 배치 캡슐로 묶어 Luna에게 일괄 위임)*

### 🔍 Parent Direct 엄격 한정 조건 (오버헤드 방지)
오버헤드 방지를 위해 Parent가 예외적으로 직접 코드를 수정할 수 있는 경우는 아래 **3가지 조건을 '동시에' 만족하는 단일 수정**으로 엄격히 한정됩니다:
1. 단일 파일 내 **3줄 이하**의 물리적 수정일 것.
2. 로직/분기문(if/else/loop) 추가가 없는 단순 오타, 리터럴/상수값 1개 변경, 단순 import 추가일 것.
3. 수정 후 테스트 실행이나 디버깅 루프가 수반되지 않고 1턴에 검증 종료될 것.

### 🚫 Routing Red Flags
- **금지**: 파일 수, 코드 줄 수, 검색 범위의 넓이만으로 Luna vs Terra를 결정하지 마십시오.
  - *10개 파일에 걸친 동일 패턴 기계적 수정* ➔ **Luna Child (low [1.00×])**
  - *1개 파일이지만 내부 구현 알고리즘/구조를 분석·선택해야 함* ➔ **Terra Child (low/medium [1.84×~2.46×])**

---

## 🚀 3. Canonical Automatic Spawn Contract

자동 경로에서는 사전에 검증된 최적의 `reasoning_effort`를 명시하며, 자식 워커가 부모 속성을 상속하지 않도록 모든 파라미터를 명시합니다.

### 1) Sol ➔ Luna Child (기계적 실행)
```text
spawn_agent(
    model = "gpt-5.6-luna",
    fork_turns = "none",
    reasoning_effort = "low",           # Light (1.00× 최적 효율)
    task_name = "<task_name>",
    message = "<Task Capsule>"
)
```

### 2) Sol ➔ Terra Child (로컬 구현 위임)
```text
spawn_agent(
    model = "gpt-5.6-terra",
    fork_turns = "none",
    reasoning_effort = "low" | "medium", # Light(1.84×) ~ Medium(2.46×)
    task_name = "<task_name>",
    message = "<Task Capsule>"
)
```

### 3) Terra ➔ Luna Child (기계적 실행)
```text
spawn_agent(
    model = "gpt-5.6-luna",
    fork_turns = "none",
    reasoning_effort = "low",           # Light (1.00× 최적 효율)
    task_name = "<task_name>",
    message = "<Task Capsule>"
)
```

---

## ⚙️ 4. Reasoning Effort 및 실측 토큰 경제학 매트릭스

### 1) GPT-5.6 모델별·추론레벨별 실 사용 토큰 비율 (기준: Luna Light = 1.00×)

| 모델 \ 추론 레벨 | Light (`low`) | Medium (`medium`) | High (`high`) | XHigh | Max |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Luna** | **1.00×** (스위트 스팟) | **3.54×** | **10.45×** | **16.60×** | **27.06×** |
| **Terra** | **1.84×** | **2.46×** (고효율) | **4.61×** | **7.99×** | **17.52×** |
| **Sol** | **3.23×** | **6.15×** (일반 부모) | **8.61×** | — | — |

### 2) 토큰 경제학 기반 3대 핵심 운용 규칙
1. **Luna의 기본값은 무조건 `low` (Light: 1.00×) 고정**:
   - Luna는 구현 패턴이 확정된 기계적 조립/테스트 전담입니다. 생각을 많이 시킬 이유가 없으며, `medium`으로 올리면 토큰이 3.54×로 급증하여 오히려 Terra Medium(2.46×)보다 비싸집니다.
2. **로컬 판단 필요 시 Terra `low` (1.84×) ~ `medium` (2.46×) 라우팅**:
   - 내부 알고리즘이나 클래스 구조 선택이 필요할 때는 Luna에게 생각을 더 시키지 말고, 더 똑똑하고 토큰을 덜 쓰는 Terra Medium(2.46×)에 위임하는 것이 약 30% 더 저렴합니다.
3. **High / Max 자동 선택 절대 금지 (비용 폭탄 방지)**:
   - `Luna High (10.45×)` 및 `Luna Max (27.06×)`는 부모인 `Sol High (8.61×)`보다 비쌉니다. 하위 모델의 High 선택은 치명적인 비용 역전(Cost Inversion)을 유발하므로 자동 선택이 엄격히 금지됩니다.

### 3) High / xhigh / max 사용자 승인 프로토콜
`low` / `medium`으로 감당할 수 없는 고난도 작업의 경우:
1. **Parent Direct 우선 평가**: Parent(Sol)가 직접 수행하는 것이 더 단순하고 빠르면 직접 수행.
2. **실익 평가 및 사용자 승인 요청**: 여전히 Child 위임 실익이 명백한 경우 사용자에게 사유와 예상 비용을 설명하고 사전 승인 요청.
   - `high`: 고난도 로컬 탐색 예외
   - `xhigh` / `max`: 극히 예외적인 품질 최우선 작업
3. **승인 범위**: 해당 특정 태스크의 단일 spawn에만 적용되며, 미승인 시 Parent가 직접 수행.

---

## 📋 5. Task Capsule 표준 구조

부모 모델은 자식 워커에게 권한 경계가 명확히 정의된 최소한의 완결된(Self-Contained) 지침을 전달합니다.

```text
TASK CAPSULE

Role:
You are a leaf worker.

Goal:
<명확한 단일 작업 목표>

Target / Scope:
<허용된 파일 / 클래스 / 함수 / 심볼 경로>

Decisions already made:
<부모 모델이 이미 확정한 요구사항, API, 동작, 호환성 결정>

Delegated authority:
<Luna: Predetermined execution only>
or
<Terra: Implementation-local analysis and choice allowed>

Must not decide:
<부모 모델 고유의 판단 영역 (Architecture, Public API, Security, Scope 변경 등)>

Exact change:
<결과 형태 자체가 계약인 경우 필수: final text, before/after 또는 고정 변환 규칙>

Preserve:
<유지해야 하는 기존 동작, 호환성, 타입 힌트>

Do not touch:
<수정 금지 영역>

Acceptance criteria:
- [ ] <유지해야 할 의미·동작·호환성 불변조건>
- [ ] <기계적 검증 결과>

Validation:
- <검증 명령 1 (예: pytest tests/test_foo.py)>
- <검증 명령 2 (예: ruff check src/foo.py)>

Recovery policy:
- At most ONE recovery attempt when appropriate.
- If recovery is not appropriate (for example, an environment or dependency failure), return TASK_FAILED without attempting recovery.
- If validation still fails after one recovery attempt, return TASK_FAILED immediately.
- Do not enter recursive retry loops.

Worker constraints:
- Do not spawn or delegate to other agents.
- Do not perform external side-effects or destructive operations.
- Stop immediately at a terminal return state.

Return protocol:
- TASK_COMPLETED, TASK_FAILED, NEEDS_PARENT_DECISION, NEEDS_PARENT_ACTION
```

---

## 🛑 6. 4대 Terminal Return Protocol

모든 Child 작업은 반드시 다음 4가지 상태 중 하나로 종료해야 합니다. 실패 또는 제어권 반환 시 Child는 자의적인 rollback(`git reset --hard` 등)을 하지 않고 현재 상태를 보존하여 보고합니다.

### 1) 정상 완료 (`TASK_COMPLETED`)
Task Capsule의 Acceptance Criteria를 대조 보고:
```text
TASK_COMPLETED

Modified files:
- <path1>
- <path2>

Validation:
- <command 1> -> PASSED
  <short evidence>
- <command 2> -> PASSED
  <short evidence>

Acceptance:
- [x] <Task Capsule acceptance criterion 1>
- [x] <Task Capsule acceptance criterion 2>

Notes:
- None
```

### 2) 복구 한도 초과 또는 미시도 실패 (`TASK_FAILED`)
```text
TASK_FAILED

Modified files:
- <path1>
- <path2>

Validation:
- <failed command> -> FAILED
  <short error evidence>

Recovery:
- Attempted: YES | NO
- <recovery summary or reason recovery was not appropriate>

Remaining blocker:
<why the task remains incomplete>

Worktree:
- Current changes preserved for Parent review.
- No automatic reset/revert/clean performed.
```

### 3) 설계 판단 필요 시 (`NEEDS_PARENT_DECISION`)
```text
NEEDS_PARENT_DECISION

Unresolved:
<새로운 모호성, 호환성 충돌 또는 설계 판단 요구사항>

Why it blocks execution:
<위임된 권한 범위를 초과하는 이유>

Relevant:
<관련 파일 / 심볼>

Worktree:
<현재 로컬 수정 상태>
```

### 4) 외부 부수효과 / 승인 필요 시 (`NEEDS_PARENT_ACTION`)
```text
NEEDS_PARENT_ACTION

Action required:
<git push, deploy, secret 설정, 승인 필요 작업>

Why needed:
<외부 권한이 필요한 이유>

Task completed so far:
<완료된 로컬 작업 및 검증 결과 요약>

Worktree:
<현재 로컬 수정 상태>
```

---

## 🔍 7. Parent Evidence Before Completion & Scope Matching

Parent는 Child의 성공 보고를 Blind Trust하지 않고 다음 순서로 완료를 확정합니다:
1. `git diff` 및 수정 파일 목록 검토
2. Task Capsule의 Acceptance 충족 여부 확인
3. **Claim-Verification Scope Matching**:
   - **원칙**: `Verification scope MUST match the completion claim scope.`
   - Parent가 사용자에게 보고하려는 완료 범위에 정확히 비례하는 **Minimum Sufficient Fresh Verification을 직접 실행**.
   - *예 (회귀 버그 수정 claim)*: `pytest tests/test_x.py::test_regression` 직접 실행.
   - *예 (전체 통과 claim)*: `pytest` 전체 직접 실행.
   - *토큰 절약 권장 보고*: "변경된 동작의 단위 테스트를 Parent가 직접 재검증하여 통과를 확인했습니다. Child는 전체 테스트 스위트 통과를 보고했습니다."

---

## 🚫 8. 합리화 방지 테이블 및 Red Flags

### 📋 Rationalization Table
| 에이전트의 핑계 | 현실 및 불변 규칙 |
| :--- | :--- |
| *"10줄 안팎의 작업이라 캡슐 만들고 spawn하는 것보다 직접 고치는 게 빠릅니다"* | **금지.** 10줄 이상 또는 테스트 루프는 이미 다운시프트 손익분기점(BEP)을 초과했습니다. Luna Light(1.00×)로 위임해야 Sol Medium(6.15×)의 다중 턴 컨텍스트 누적 비용을 80% 이상 절감합니다. |
| *"지금 한창 구현 흐름 중이니 이번 한 번만 직접 코딩할게요"* | **금지.** '이번 한 번만'은 항상 세션 전체의 전면 자가 구현으로 변질됩니다. 코드 수정 도구를 호출하기 전에 즉시 Task Capsule을 작성하십시오. |
| *"Luna가 복잡한 로직을 풀 수 있게 reasoning을 High로 올릴게요"* | **비용 폭탄.** 실측 데이터상 Luna High(10.45×)는 Sol High(8.61×)보다 비쌉니다. 로컬 추론이 필요하면 Terra Light(1.84×)/Medium(2.46×)으로 라우팅하십시오. |
| *"1줄짜리 오타/상수 수정인데 이것도 무조건 캡슐 만들어야 하나요?"* | **아닙니다.** 3줄 이하, 무로직, 무테스트 단발 수정은 캡슐 오버헤드 방지를 위해 Parent Direct가 경제적이며 원칙입니다. |
| *"수정 파일이 많으니 Luna 대신 Terra로 보낼게요"* | 파일 수가 아니라 **남은 판단 권한**이 기준입니다. 패턴이 닫혀 있으면 10개 파일도 Luna로 일괄 배치 위임합니다. |
| *"DB migration이지만 SQL이 확정되었으니 Luna에 위임할게요"* | Gate A(High Consequence) 위반입니다. 파괴적/운영 변경은 무조건 **Parent Direct**입니다. |
| *"Terra child 생성이 실패했으니 Luna child로 재시도해볼게요"* | Fail-Closed 불변 규칙 위반입니다. spawn 실패 시 **Parent가 직접 수행**합니다. |
| *"Validation이 또 실패했지만 한 번만 더 고쳐볼게요"* | Recovery는 **최대 1회**입니다. 2차 실패 시 즉시 `TASK_FAILED`로 반환해야 합니다. |
| *"Child가 다 통과했다고 보고했으니 그대로 완료 처리할게요"* | Blind Trust 금지. Parent가 직접 자신의 claim에 맞는 fresh verification을 수행해야 합니다. |

### 🚩 Red Flags - STOP and Correct
- ❌ 10줄 이상 코드 작성이나 테스트 검증이 필요한 작업을 Parent가 직접 수정함
- ❌ Luna에게 `reasoning_effort="medium"` 이상을 자동 지정함 (Luna는 `low` [1.00×] 고정)
- ❌ Gate A(Safety)를 건너뛰고 Gate B로 직행함
- ❌ DB 마이그레이션, 보안, 배포 작업이 Child에 위임됨
- ❌ Sol 자식에서 Sol이 생성되거나 Terra 자식에서 Terra가 생성됨 (모델 상속 실패)
- ❌ Terra Child가 또 다른 Child agent를 생성함 (Chaining 시도)
- ❌ 사용자 승인 없이 `high`, `xhigh`, `max` reasoning effort를 자동 선택함
- ❌ Child가 실패 후 `git reset --hard` 등으로 작업트리를 자의적으로 날려버림
- ❌ Parent가 fresh verification을 일체 수행하지 않고 완료를 선언함

---

## 📚 9. 참조 문서
- [위임 모범 사례 및 11대 실전 시나리오](references/delegation-examples.md)
- [Task Capsule 및 4대 반환 프로토콜 표준 서식](references/task-capsule-template.md)
- [프로젝트 상세 기획 명세서](../../docs/codex-downshift-spec.md)


