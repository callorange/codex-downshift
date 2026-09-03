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
7. **Reasoning Effort & 모델 정책 (Luna-First & Sol-Parent Golden Switch)**:
   - **Luna**: 기본값 `low` (Light: 1.00×). 경량 심볼/위치 탐색 시 `medium` (2.61×)까지 허용 (단, 구현 판단 권한은 확장되지 않음).
   - **Terra**: 기본값 `medium` (5.35×) (Sol Parent 전용 로컬 구현 워커).
   - **Sol-Parent Golden Switch**: Sol Parent에서 로컬 구현 선택이 필요한 경우, Luna High(6.00×, 40 steps)보다 상위 체급과 적은 step의 Terra Medium(5.35×, 20 steps)을 우선 선택. (※ Terra Parent는 자식 호출 없이 **Terra Direct**).
   - **자동 선택 금지**: `high` / `xhigh` / `max`는 자동 선택 절대 금지 (사용자 명시적 요청/승인 시에만 예외 허용).
   - *(소모 지수 상세 근거 및 주의사항은 [Model Economics](references/model-economics.md) 참조)*
8. **Max 1 Recovery**: Child validation 실패 시 자체 구현 수정은 가능한 경우에 한해 최대 1회만 허용(환경/의존성 등 부적절한 경우 미시도). 재실행 실패 또는 미시도 시 즉시 `TASK_FAILED`로 중단.
9. **Structured Return Protocols**: Child는 반드시 4대 반환 프로토콜(`TASK_COMPLETED`, `TASK_FAILED`, `NEEDS_PARENT_DECISION`, `NEEDS_PARENT_ACTION`) 중 하나로 종료하며, 임의로 destructive rollback(`git reset --hard` 등)을 수행하지 않음.
10. **Evidence Before Completion (Scope Matching)**: Parent는 Child 결과를 Blind Trust하지 않으며, **자신이 하려는 Completion Claim의 범위와 정확히 일치하는 Minimum Sufficient Fresh Verification을 직접 수행**.

---

## 🛑 The Parent Execution Protocol (4단계 다운시프트 루프)

Parent는 소스 코드 편집 도구(`write_to_file`, `replace_file_content` 등)를 직접 호출하기 전에 **반드시** 아래 4단계를 순서대로 수행해야 합니다:

1. **Trigger & Gate Check**: 
   - [선행 조건] 상위 요구사항/아키텍처/보안 판단이 Parent에 의해 완료되었는가? (미완료 시 Parent Direct로 추론 완료 우선)
   - [임계값 대조] 10줄 이상, 테스트 사이클 수반, 또는 다중 파일인가? (Default Downshift Threshold 충족 확인)
   - ➔ 충족 시 Gate A(안전성) 통과 확인 후 Gate B(잔여 권한)로 워커 모델 결정.
2. **Capsule Emission**: 
   - [Task Capsule 표준 서식](references/task-capsule-template.md)에 따라 목표, 허용 범위, Acceptance Criteria, 검증 명령을 확정하여 프롬프트 작성.
3. **Leaf Worker Spawn**: 
   - `spawn_agent`로 하위 모델을 명시하여 디스패치 (`fork_turns = "none"`, Luna는 `reasoning_effort = "low"`, Terra는 `medium`).
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
  ├─ 2. 사소한 단발 수정인가?
  │    ├─ ≤3줄 오타/상수 수정 (무로직, 무테스트) ──────→ Parent Direct (오버헤드 방지)
  │    ├─ 4~9줄 단일 파일 수정 (무로직, 무테스트, 1턴) ─→ Parent 선택 가능 (단, 테스트/탐색 필요 시 다운시프트)
  │    └─ ≥10줄 OR 테스트 루프 OR 다중 파일 ──────────→ 다운시프트 평가 진입 (Threshold 충족)
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
│ ├─ Implementation 닫힘 + 경량 위치 탐색 필요              │
│ │  ──────────────────────────→ Luna Medium Child (2.61×) │
│ └─ Implementation까지 닫힌 기계적 조립/테스트              │
│    ──────────────────────────→ Luna Low Child (1.00×)    │
│                                                          │
│ (Active Terra Parent)                                    │
│ ├─ Implementation-local 분석/선택 남음                    │
│ │  ──────────────────────────→ Terra Parent Direct       │
│ ├─ Implementation 닫힘 + 경량 위치 탐색 필요              │
│ │  ──────────────────────────→ Luna Medium Child (2.61×) │
│ └─ Implementation까지 닫힌 기계적 조립/테스트              │
│    ──────────────────────────→ Luna Low Child (1.00×)    │
└──────────────────────────────────────────────────────────┘
```

### 🚀 Default Downshift Threshold (Provisional BEP Heuristic)

Parent의 자의적인 직접 구현 합리화를 방지하기 위해 실사용 로그 축적 전까지 다음 보수적 기본 휴리스틱을 다운시프트 기본 임계값으로 적용합니다:

1. **테스트/검증 사이클 (Test & Validation Loop)**: 단위 테스트를 작성하거나 테스트 명령어를 실행해 결과를 검증·수정해야 하는 모든 작업.
2. **코드 규모 (Scale Threshold: 10줄 이상)**: 새로 작성하거나 변경할 코드가 **10줄 이상**(또는 함수/클래스 1개 단위)인 작업.
3. **다중 파일 범위 (Multi-File Scope)**: 수정 대상이 **2개 이상의 파일**에 걸쳐 있는 작업.

> [!NOTE]
> 위 기준은 공식 보장 손익분기점이 아니며, Parent가 사소한 실행까지 계속 직접 수행하는 것을 막기 위한 기본 운영 heuristic입니다.
> Threshold는 다운시프트 평가 진입 여부를 결정합니다. Gate A는 위임 자체의 허용 여부를 결정하며, Gate A를 통과한 경우 Gate B가 남은 Decision Authority에 따라 최종 실행 경로를 결정합니다 (`Threshold decides whether to evaluate downshift. Gate A decides whether delegation is allowed. If Gate A passes, Gate B decides the execution path based on remaining Decision Authority.`).

### 🔍 Parent Direct 허용 조건 및 4~9줄 구간 처리
- **≤3줄 단발 수정**: 단일 파일 3줄 이하, 로직/분기 없는 오타/상수 변경, 무테스트 1턴 종료 건은 캡슐 오버헤드 방지를 위해 Parent Direct 처리.
- **4~9줄 단일 파일 구간**: implementation closed 상태이고 테스트 루프나 추가 탐색 없이 1턴에 검증 가능한 경우에 한해 Parent Direct 선택 가능. 단, **테스트/수정 사이클이 필요하면 4줄이라도 반드시 다운시프트**.

---

## 🚀 3. Canonical Automatic Spawn Contract

자동 경로에서는 자식 워커가 부모 속성을 상속하지 않도록 모든 파라미터를 명시합니다.

### 1) Sol ➔ Luna Child (기계적 실행)
```text
spawn_agent(
    model = "gpt-5.6-luna",
    fork_turns = "none",
    reasoning_effort = "low",           # 기본값: low (경량 위치 탐색 시 medium)
    task_name = "<task_name>",
    message = "<Task Capsule>"
)
```

### 2) Sol ➔ Terra Child (로컬 구현 위임, Sol Parent 전용)
```text
spawn_agent(
    model = "gpt-5.6-terra",
    fork_turns = "none",
    reasoning_effort = "medium",        # 기본값: medium
    task_name = "<task_name>",
    message = "<Task Capsule>"
)
```

### 3) Terra ➔ Luna Child (기계적 실행)
```text
spawn_agent(
    model = "gpt-5.6-luna",
    fork_turns = "none",
    reasoning_effort = "low",           # 기본값: low (경량 위치 탐색 시 medium)
    task_name = "<task_name>",
    message = "<Task Capsule>"
)
```

---

## ⚙️ 4. Reasoning Effort 및 비용 요약

| 구성 (Configuration) | 예상 소모 지수 (Est. Index) | vs Sol Low (9.40×) | vs Sol Medium (18.04×) | 주요 역할 |
| :--- | :---: | :---: | :---: | :--- |
| **Luna Low** | **1.00×** | ~89.4% lower | ~94.5% lower | 확정된 기계적 조립/테스트 디폴트 |
| **Luna Medium** | **2.61×** | ~72.2% lower | ~85.5% lower | 구현 닫힘 + 경량 심볼/위치 탐색 |
| **Terra Medium** | **5.35×** | ~43.1% lower | ~70.3% lower | 로컬 알고리즘/구조 설계 (Sol Parent 전용) |

- **Luna-First**: 구현이 닫힌 작업은 Luna Low(1.00×) 또는 Luna Medium(2.61×)을 우선 활용. (Luna Medium은 구현 판단 권한을 확장하지 않음).
- **Sol-Parent Golden Switch**: Sol Parent에서 로컬 구현 선택이 필요한 경우, Luna High(6.00×, 40 steps) 대신 Terra Medium(5.35×, 20 steps)을 사용. (Terra Parent는 Terra Direct).
- **High 이상 자동 선택 금지**: `high`, `xhigh`, `max`는 자동 선택되지 않으며, 사용자 사전 승인 시에만 예외적 허용.
- *(공식 크레딧 요율, 추정 소모 지수 산출 근거, 캐시 계산 예시는 [Model Economics](references/model-economics.md) 참조)*

---

## 📋 5. Task Capsule 표준 구조

부모 모델은 자식 워커에게 권한 경계가 명확히 정의된 최소한의 완결된(Self-Contained) 지침을 전달합니다.

```text
TASK CAPSULE

Role: You are a leaf worker.
Goal: <명확한 단일 작업 목표>
Target / Scope: <허용된 파일 / 클래스 / 함수 / 심볼 경로>
Decisions already made: <부모 모델이 이미 확정한 요구사항, API, 동작, 호환성 결정>
Delegated authority:
- Luna: Predetermined execution only (or bounded local exploration)
- Terra: Implementation-local analysis and choice allowed within fixed contracts
Must not decide: <부모 모델 고유의 판단 영역 (Architecture, Public API, Security 등)>
Exact change: <결과 형태 자체가 계약인 경우: final text, before/after 또는 변환 규칙>
Preserve: <유지해야 하는 기존 동작, 호환성, 타입 힌트>
Do not touch: <수정 금지 영역>
Acceptance criteria:
- [ ] <유지해야 할 의미·동작·호환성 불변조건>
- [ ] <기계적 검증 결과>
Validation:
- <검증 명령 (예: pytest tests/test_foo.py)>
Recovery policy:
- At most ONE recovery attempt when appropriate.
- If recovery is not appropriate or validation still fails, return TASK_FAILED immediately.
Worker constraints:
- Do not spawn or delegate to other agents.
- Do not perform external side-effects or destructive operations.
Return protocol:
- TASK_COMPLETED, TASK_FAILED, NEEDS_PARENT_DECISION, NEEDS_PARENT_ACTION
```

---

## 🛑 6. 4대 Terminal Return Protocol

모든 Child 작업은 반드시 다음 4가지 상태 중 하나로 종료해야 합니다. Child는 자의적인 rollback(`git reset --hard` 등)을 하지 않고 현재 상태를 보존하여 보고합니다.

1. **`TASK_COMPLETED`**: Acceptance criteria 충족 및 검증 통과 증거 보고.
2. **`TASK_FAILED`**: 1회 복구 실패 또는 복구 미시도 후 작업트리 보존 및 실패 원인 상세 보고.
3. **`NEEDS_PARENT_DECISION`**: 작업 도중 위임 범위를 넘는 새로운 설계/동작 판단 직면 시 보고 후 제어권 반환.
4. **`NEEDS_PARENT_ACTION`**: `git push`, `deploy`, 비밀값 등 외부 권한 작업 필요 시 보고 후 제어권 반환.

*(상세 서식 및 예시는 [Task Capsule Template](references/task-capsule-template.md) 참조)*

---

## 🔍 7. Parent Evidence Before Completion & Scope Matching

Parent는 Child의 성공 보고를 Blind Trust하지 않고 다음 순서로 완료를 확정합니다:
1. `git diff` 및 수정 파일 목록 검토.
2. Task Capsule의 Acceptance 충족 여부 확인.
3. **Claim-Verification Scope Matching**:
   - **원칙**: `Verification scope MUST match the completion claim scope.`
   - Parent가 사용자에게 보고하려는 완료 범위에 정확히 비례하는 **Minimum Sufficient Fresh Verification을 직접 실행**.
   - *(예: 특정 회귀 버그 claim ➔ 해당 단위 테스트 직접 실행)*.

---

## 🚫 8. 합리화 방지 테이블 및 Red Flags

### 📋 Rationalization Table
| 에이전트의 핑계 | 현실 및 불변 규칙 |
| :--- | :--- |
| *"10줄 안팎의 작업이라 캡슐을 만들고 spawn하는 것보다 직접 고치는 게 빠릅니다"* | **금지.** 10줄 이상 또는 테스트/검증 루프는 Default Downshift Threshold를 충족합니다. 먼저 Gate A에서 위임 안전성을 평가하십시오. **Gate A 실패 시 Parent Direct**, Gate A를 통과한 경우에만 Gate B에서 남은 Decision Authority에 따라 Luna Low / Luna Medium / Terra Medium 또는 Terra Parent Direct 경로를 결정합니다. Threshold 자체는 Child 모델을 결정하지 않습니다 (`Threshold decides whether to evaluate downshift. Gate A decides whether delegation is allowed. If Gate A passes, Gate B decides the execution path based on remaining Decision Authority.`). |
| *"지금 한창 구현 흐름 중이니 이번 한 번만 직접 코딩할게요"* | **금지.** '이번 한 번만'은 세션 전체의 전면 자가 구현으로 변질됩니다. 코드 수정 도구 호출 전 Task Capsule을 작성하십시오. |
| *"Luna가 복잡한 로직을 풀 수 있게 reasoning을 High로 올릴게요"* | **비효율.** Luna High(6.00×, 40 steps)는 Terra Medium(5.35×, 20 steps)보다 예상 소모 지수와 step 효율이 떨어집니다. Sol Parent에서는 Terra Medium을 호출하고, Terra Parent에서는 직접 수행하십시오. |
| *"1줄짜리 오타/상수 수정인데 이것도 무조건 캡슐 만들어야 하나요?"* | **아닙니다.** 3줄 이하, 무로직, 무테스트 단발 수정은 캡슐 오버헤드 방지를 위해 Parent Direct가 원칙입니다. |
| *"수정 파일이 많으니 Luna 대신 Terra로 보낼게요"* | 파일 수가 아니라 **남은 판단 권한**이 기준입니다. 패턴이 닫혀 있으면 10개 파일도 Luna로 일괄 배치 위임합니다. |
| *"DB migration이지만 SQL이 확정되었으니 Luna에 위임할게요"* | Gate A(High Consequence) 위반입니다. 파괴적/운영 변경은 무조건 **Parent Direct**입니다. |
| *"Terra child 생성이 실패했으니 Luna child로 재시도해볼게요"* | Fail-Closed 불변 규칙 위반입니다. spawn 실패 시 **Parent가 직접 수행**합니다. |
| *"Validation이 또 실패했지만 한 번만 더 고쳐볼게요"* | Recovery는 **최대 1회**입니다. 2차 실패 시 즉시 `TASK_FAILED`로 반환해야 합니다. |
| *"Child가 다 통과했다고 보고했으니 그대로 완료 처리할게요"* | Blind Trust 금지. Parent가 직접 자신의 claim에 맞는 fresh verification을 수행해야 합니다. |

### 🚩 Red Flags - STOP and Correct
- ❌ 10줄 이상 코드 작성이나 테스트 검증이 필요한 작업을 Parent가 직접 수정함
- ❌ 자동 경로에서 Luna에게 `high` reasoning effort를 지정함
- ❌ Terra Parent가 Terra Child를 spawn 시도함 (Downshift Only 위반)
- ❌ Gate A(Safety)를 건너뛰고 Gate B로 직행함
- ❌ DB 마이그레이션, 보안, 배포 작업이 Child에 위임됨
- ❌ Sol 자식에서 Sol이 생성되거나 Terra 자식에서 Terra가 생성됨 (모델 상속 실패)
- ❌ Terra Child가 또 다른 Child agent를 생성함 (Chaining 시도)
- ❌ 사용자 승인 없이 `high`, `xhigh`, `max` reasoning effort를 자동 선택함
- ❌ Child가 실패 후 `git reset --hard` 등으로 작업트리를 자의적으로 날려버림
- ❌ Parent가 fresh verification을 일체 수행하지 않고 완료를 선언함

---

## 📚 9. 참조 문서
- [Model Economics & Estimated Consumption Index](references/model-economics.md)
- [위임 모범 사례 및 11대 실전 시나리오](references/delegation-examples.md)
- [Task Capsule 및 4대 반환 프로토콜 표준 서식](references/task-capsule-template.md)
- [프로젝트 상세 기획 명세서](../../docs/codex-downshift-spec.md)
