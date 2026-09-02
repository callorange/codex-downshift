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

---

## 2. 프로젝트 목표 및 핵심 철학

`codex-downshift`는 사용자가 선택한 Active Parent 모델의 판단권을 유지하면서, **이미 충분히 결정된 실행 작업만 더 낮은 tier의 Child 모델로 안전하게 하향 위임**하여 다음을 줄이는 것이다.

* Sol / Terra 사용량
* 상위 모델의 반복 비용
* 무분별한 상향 위임이나 무한 루프로 인한 토큰 낭비

### 핵심 불변 원칙 (The Core Invariant)
> **"Safe enough to delegate → delegate only the remaining authority → keep every child leaf-only → return structured evidence → let the Parent make only claims it freshly verified."**

---

## 3. 10대 핵심 불변 규칙 (10 Core Invariants)

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
8. **Max 1 Recovery**: Child validation 실패 시 자체 구현 수정은 최대 1회만 허용. 재실행 실패 시 즉시 `TASK_FAILED`로 중단.
9. **Structured Return Protocols**: Child는 반드시 4대 반환 프로토콜(`TASK_COMPLETED`, `TASK_FAILED`, `NEEDS_PARENT_DECISION`, `NEEDS_PARENT_ACTION`) 중 하나로 종료하며, 임의로 destructive rollback(`git reset --hard` 등)을 수행하지 않음.
10. **Evidence Before Completion (Scope Matching)**: Parent는 Child 결과를 Blind Trust하지 않으며, **자신이 하려는 Completion Claim의 범위와 정확히 일치하는 Minimum Sufficient Fresh Verification을 직접 수행**.

---

## 4. 2단계 결정적 라우팅 파이프라인 (Routing Pipeline)

```text
Active Parent (Sol or Terra)
  │
  ├─ 1. Trivial Atomic Action 단독인가?
  │    YES ──────────────────────────────────────────→ Parent Direct (오버헤드 방지)
  │    NO
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
│ ├─ Semantic / Architecture / API / Security 판단 남음     │
│ │  ─────────────────────────────────────────→ Sol Direct │
│ ├─ Semantic 닫힘 + Implementation-local 분석/선택 남음    │
│ │  ─────────────────────────────────────────→ Terra Child│
│ └─ Implementation까지 닫힌 기계적 실행                    │
│    ─────────────────────────────────────────→ Luna Child │
│                                                          │
│ (Active Terra Parent)                                    │
│ ├─ Implementation까지 닫힌 기계적 실행                    │
│ │  ─────────────────────────────────────────→ Luna Child │
│ └─ 그 외 모든 작업 (판단 필요 작업 포함)                   │
│    ─────────────────────────────────────────→ Terra Direct│
└──────────────────────────────────────────────────────────┘
```

---

## 5. 역할별 Decision Authority 모델 매트릭스

| 실행 주체 | 역할 성격 | 허용되는 판단 권한 | 금지된 판단 권한 |
| :--- | :--- | :--- | :--- |
| **Sol / Terra (Active Parent)** | High-Level Authority | 요구사항 해석, 제품 정책, Architecture, Public API, DB 마이그레이션, 보안, 승인 결정 | 위임된 하위 워커의 자율적 상위 결정 |
| **Terra Child** (Sol Parent 전용) | Implementation-Local Worker | 확정된 API/동작 계약 내부의 로컬 알고리즘, 내부 클래스/자료구조 선택, 로컬 리팩토링 | Public API 변경, 제품 정책 변경, DB 스키마 변경, 보안 정책 수정 |
| **Luna Child** (Sol/Terra 공용) | Predetermined Leaf Executor | 확정된 패턴 적용, 명시된 코드 조립, 기계적 린트/타입/문서 수정, 확정된 테스트 실행 | 구현 알고리즘/자료구조 선택, 호환성 정책 변경, 상위 설계 판단 |

---

## 6. Canonical Automatic Spawn Contract

```text
# 1) Sol ➔ Luna Child
spawn_agent(
    model = "gpt-5.6-luna",
    fork_turns = "none",
    reasoning_effort = "low" | "medium",
    task_name = "<task_name>",
    message = "<Task Capsule>"
)

# 2) Sol ➔ Terra Child
spawn_agent(
    model = "gpt-5.6-terra",
    fork_turns = "none",
    reasoning_effort = "low" | "medium",
    task_name = "<task_name>",
    message = "<Task Capsule>"
)

# 3) Terra ➔ Luna Child
spawn_agent(
    model = "gpt-5.6-luna",
    fork_turns = "none",
    reasoning_effort = "low" | "medium",
    task_name = "<task_name>",
    message = "<Task Capsule>"
)
```

---

## 7. 4대 Terminal Return Protocol

1. **`TASK_COMPLETED`**: 다중 Validation 증거와 Acceptance Criteria 대조 결과 반환
2. **`TASK_FAILED`**: 1회 복구 실패 후 작업트리를 보존하며 실패 블로커 상세 보고
3. **`NEEDS_PARENT_DECISION`**: 새 설계 판단이나 모호성 직면 시 부모에게 제어권 반환
4. **`NEEDS_PARENT_ACTION`**: git push, deploy 등 외부 부수효과 필요 시 부모에게 제어권 반환

---

## 8. Evidence Before Completion & Scope Matching

Parent는 Child의 성공 보고를 무조건 신뢰(Blind Trust)하지 않으며 다음 원칙을 준수한다:
- **`Verification scope MUST match the completion claim scope.`**
- Parent가 보고하려는 claim 범위에 비례하는 **Minimum Sufficient Fresh Verification을 직접 수행**.

---

## 9. 구현 완료 및 히스토리

### v0.1.4 (Tiered Downshift & Safety Gates)
- [x] 10 Core Invariants 정립 및 `SKILL.md` Token Diet 적용
- [x] 2단계 라우팅 파이프라인 (Gate A Safety ➔ Gate B Decision Authority) 구현
- [x] Sol ➔ Terra / Luna 및 Terra ➔ Luna Tiered Downshift 체계 구현
- [x] 4대 Terminal Return Protocols 표준화 (`task-capsule-template.md`)
- [x] 10대 핵심 실전 시나리오 구축 (`delegation-examples.md`)
- [x] Scope-Matched Fresh Verification 원칙 정립
- [x] README.md 및 codex-downshift-spec.md 동기화

---

## 10. 설치 및 배포 정책

- **글로벌 격리 설치**: `~/.codex/skills/codex-downshift/` (타 에이전트의 전역 오인식 방지)
- **프로젝트 로컬 설치**: `<project-root>/.agents/skills/codex-downshift/`
- **표준 CLI 명령어**:
  ```bash
  npx skills@latest add callorange/codex-downshift --skill codex-downshift --agent codex --global
  ```

---

## 11. 구현 시 중요한 금지사항 (Non-Goals)

- 범용 AI model router나 임의 switching을 구현하지 않는다.
- 상향 에스컬레이션(`Luna/Terra ➔ Sol`)이나 수평 전환을 구현하지 않는다.
- 별도의 daemon, config 시스템, runtime wrapper를 추가하지 않는다.
- `high`/`xhigh`/`max` reasoning effort를 자동 spawn에 사용하지 않는다.

---

## 12. Acknowledgements & Reference

Parts of the delegation safety design and execution constraints were inspired by [codex-auto-model-router](https://github.com/orange-the-weak/codex-auto-model-router), particularly its bounded task delegation, task capsule structure, validation budget, and fail-safe execution concepts. `codex-downshift` was independently redesigned and implemented to serve as a lightweight, instruction-only skill focusing strictly on Parent-controlled downshifting with Tiered Downshift and 2-stage safety gates.
