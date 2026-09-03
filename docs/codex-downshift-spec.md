# codex-downshift — Project Specification

> Status: v0.1.4 implemented / Tiered Downshift & 2-Stage Safety Gates established
> Target: OpenAI Codex  
> Artifact purpose: Antigravity 등 코딩 에이전트가 이 문서를 기반으로 프로젝트를 생성·구현·유지보수할 수 있도록 하는 통합 기획 명세서

---

## 1. 프로젝트 이름 및 설명

### Repository name
`codex-downshift`

### GitHub description

**English**
> A lightweight Codex skill that keeps Sol or Terra as the parent and offloads (downshifts) bounded execution tasks to Luna (`gpt-5.6-luna`) or Terra (`gpt-5.6-terra`) to reduce usage and costs.

**한국어**
> Sol 또는 Terra를 부모 모델로 유지하면서, 2단계 안전 게이트를 통과한 실행 작업만을 Luna (`gpt-5.6-luna`) 또는 Terra (`gpt-5.6-terra`)로 다운시프트(하향 위임)해 Codex 사용량을 절감하는 경량 Skill.

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

- 있다면: 2단계 안전 게이트(Gate A Safety ➔ Gate B Decision Authority)를 거쳐 적합한 하위 모델(Luna 또는 Terra)에 위임한다.
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

이 상태에서 실제 단순 수정까지 계속 Sol/Terra가 직접 수행하면 비싼 모델의 사용량을 기계적인 실행에 낭비하게 된다.
`codex-downshift`는 상위 판단 권한을 온전히 보존하면서 그 마지막 실행 단계를 하위 워커에 안전하게 offload하는 것을 목표로 한다.

---

## 4. 10대 핵심 불변 규칙 (10 Core Invariants)

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
7. **Reasoning Effort Policy (No automatic above medium)**:
   - `low` / `medium`: 자동 선택 허용 (기본값: `medium`).
   - `high` / `xhigh` / `max`: 자동 선택 절대 금지. Parent Direct보다 다운시프트 실익이 명백한 경우에 한해 사용자 명시적 승인 후 예외적 사용.
   - *Reasoning effort 상승은 사고 깊이만 늘릴 뿐 위임된 판단 권한(Decision Authority)을 확장하지 않음.*
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

## 6. 2단계 결정적 라우팅 파이프라인 (Gate A & Gate B)

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

### 6.1 Downshift Mandatory Trigger (즉시 호출 기준: 손익분기점)
상위 판단이 끝난 실행 작업 중 다음 3가지 중 하나라도 충족되면 다운시프트 손익분기점(BEP)을 초과하므로 **반드시 하위 워커를 호출**:
1. **테스트/검증 루프**: 단위 테스트를 작성하거나 테스트 명령어를 실행해 결과를 검증해야 하는 작업.
2. **코드 규모**: 10줄 이상(또는 함수/클래스 1개 단위)의 코드 작성/수정.
3. **다중 파일 범위**: 2개 이상의 파일에 걸친 변경 (배치 위임).

### 6.2 Parent Direct 엄격 한정 조건
오버헤드 방지를 위한 Parent 직접 수정은 아래 3조건을 **동시에 만족하는 경우에만 한정 허용**:
1. 단일 파일 내 **3줄 이하** 수정.
2. 로직/분기문(if/else/loop) 추가가 없는 오타, 상수/리터럴 1개 변경, 단순 import 추가.
3. 수정 후 테스트 루프나 디버깅 없이 1턴에 검증 종료.

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
    reasoning_effort = "low",        # [필수] Light (1.00× 최적 효율)
    task_name = "<task_name>",
    message = "<Task Capsule>"
)

# 2) Sol ➔ Terra (로컬 구현 위임, Sol Parent 전용)
spawn_agent(
    model = "gpt-5.6-terra",         # [필수] Terra 모델 명시
    fork_turns = "none",             # [필수] 부모 대화 제외, fresh context
    reasoning_effort = "low"|"medium", # [필수] Light(1.84×) ~ Medium(2.46×)
    task_name = "<task_name>",
    message = "<Task Capsule>"
)
```

### 8.1 Fail-Closed Fallback Invariant (불변 규칙)
- Child 생성이 실패하거나 미지원 환경인 경우:
  - 타 모델로 우회하거나 `model`을 생략한 child를 재시도하지 않는다.
  - **현재 부모 모델(Sol/Terra)이 해당 작업을 직접 계속 수행한다.**

### 8.2 GPT-5.6 실측 토큰 경제학 매트릭스 및 Reasoning Effort 정책

| 모델 \ 추론 레벨 | Light (`low`) | Medium (`medium`) | High (`high`) | XHigh | Max |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Luna** | **1.00×** (스위트 스팟) | **3.54×** | **10.45×** | **16.60×** | **27.06×** |
| **Terra** | **1.84×** | **2.46×** (고효율) | **4.61×** | **7.99×** | **17.52×** |
| **Sol** | **3.23×** | **6.15×** (일반 부모) | **8.61×** | — | — |

- **Luna 스위트 스팟 (`low` 고정)**: Luna는 기계적 조립 전담이므로 `low`(1.00×)로 고정한다. `medium`으로 올리면 토큰이 3.54×로 급증해 Terra Medium(2.46×)보다 비싸진다.
- **로컬 판단 라우팅**: 내부 알고리즘/클래스 선택이 필요할 때는 Luna Medium(3.54×) 대신 Terra `low`(1.84×) 또는 `medium`(2.46×)으로 라우팅하여 약 30% 비용을 절감한다.
- **High / Max 자동 선택 절대 금지**: `Luna High (10.45×)`는 `Sol High (8.61×)`보다 비싸므로 비용 역전이 일어난다. 사용자 명시적 승인 없이 자동 선택을 금지한다.
- **권한 불변 원칙**: Reasoning effort는 사고 깊이만 변경할 뿐, **Child에게 위임된 판단 권한(Decision Authority)을 절대 확장하지 않는다.**

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
```text
TASK CAPSULE
Role: You are a leaf worker.
Goal: Update docstring for UserService.create_user.
Target: src/services/user_service.py :: UserService.create_user
Exact change: Replace the existing docstring with the provided Google Style docstring verbatim.
Preserve: Signature, implementation, and type hints.
Acceptance criteria: Docstring matches Exact change verbatim; ruff check passes.
Validation: ruff check src/services/user_service.py
Recovery policy: At most ONE recovery attempt when appropriate. If recovery is not appropriate or validation still fails, return TASK_FAILED immediately.
Return protocol: TASK_COMPLETED, TASK_FAILED, NEEDS_PARENT_DECISION, NEEDS_PARENT_ACTION
```

---

## 13. Task Capsule 표준 서식 & 4대 Terminal Return Protocols

### 13.1 Task Capsule 핵심 서식
```text
TASK CAPSULE
Role: You are a leaf worker.
Goal: <명확한 단일 작업 목표>
Target / Scope: <허용된 파일 / 심볼 경로>
Decisions already made: <부모 모델이 이미 확정한 요구사항, API, 동작 결정>
Delegated authority: <Luna: Predetermined execution / Terra: Implementation-local choice>
Must not decide: <부모 모델 고유의 판단 영역>
Exact change: <결과 형태가 계약인 경우 필수: final text 또는 고정 변환 규칙>
Preserve: <유지해야 하는 기존 동작/호환성>
Do not touch: <수정 금지 영역>
Acceptance criteria:
- [ ] <유지해야 할 의미·동작 불변조건>
- [ ] <기계적 검증 결과>
Validation:
- <검증 명령 1>
- <검증 명령 2>
Recovery policy: At most ONE recovery attempt when appropriate. If recovery is not appropriate or validation still fails, return TASK_FAILED immediately.
Worker constraints: Leaf worker only. Do not spawn agents. Do not perform destructive rollbacks.
Return protocol: TASK_COMPLETED, TASK_FAILED, NEEDS_PARENT_DECISION, NEEDS_PARENT_ACTION
```

### 13.2 4대 Terminal Return Protocols
1. **`TASK_COMPLETED`**: 다중 Validation 증거와 Acceptance Criteria 대조 결과 반환
2. **`TASK_FAILED`**: 1회 복구 실패 또는 미시도 후 작업트리를 보존하며 실패 블로커 상세 보고 (`Attempted: YES | NO`)
3. **`NEEDS_PARENT_DECISION`**: 새 설계 판단이나 모호성 직면 시 부모에게 제어권 반환
4. **`NEEDS_PARENT_ACTION`**: git push, deploy 등 외부 부수효과 필요 시 부모에게 제어권 반환

---

## 14. Trivial Task Delegation & 작업 단위 정책 (Task Granularity)

1. **배치 위임 원칙 (Batching)**: 서로 관련된 여러 개의 작고 명확한 작업은 개별 직접 수정하지 않고 하나의 Bounded Task Capsule로 묶어 Luna에게 일괄 위임한다.
2. **손익분기점(BEP) 기반 즉시 호출 기준**: 상위 판단이 완료된 작업 중 10줄 이상 코딩, 단위 테스트/검증 루프 수반, 다중 파일 변경 시 무조건 다운시프트를 발동한다. (Sol Medium 6.15× 대비 Luna Light 1.00×로 약 84% 절감 효과 달성).
3. **Parent Direct 엄격 한정 조건**: 오버헤드 방지를 위한 부모 직접 수정은 단일 파일 3줄 이하, 로직/분기 추가 없는 단순 오타/상수/리터럴 수정, 테스트 루프 없는 1턴 검증으로 엄격히 한정한다.
4. **우선순위 불변 원칙**: 단순 편의성이나 Latency보다 **Parent Usage 절감이 최우선**이다.

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

- **글로벌 스킬 설치 (전역 격리)**: `~/.codex/skills/codex-downshift/` (타 에이전트의 전역 오인식 방지)
- **프로젝트 로컬 설치**: `<project-root>/.agents/skills/codex-downshift/`
- **표준 CLI 설치**:
  ```bash
  npx skills@latest add callorange/codex-downshift --skill codex-downshift --agent codex --global
  ```

---

## 22. Acknowledgements & References

Parts of the delegation safety design and execution constraints were inspired by [codex-auto-model-router](https://github.com/orange-the-weak/codex-auto-model-router), particularly its bounded task delegation, task capsule structure, validation budget, and fail-safe execution concepts. `codex-downshift` was independently redesigned and implemented to serve as a lightweight, instruction-only skill focusing strictly on Parent-controlled downshifting with Tiered Downshift and 2-stage safety gates.

---

## 23. 한 문장 정의

> **Keep the user's Sol or Terra parent in control, and offload bounded execution work to Luna & Terra.**

한국어:
> **사용자가 선택한 Sol 또는 Terra의 판단권은 유지하고, 2단계 안전 게이트를 통과한 실행 작업만 Luna 또는 Terra에 안전하게 하향 위임한다.**
